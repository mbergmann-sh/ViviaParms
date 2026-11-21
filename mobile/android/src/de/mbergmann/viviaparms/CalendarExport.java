// ViviaParms Tablet – Termine in einen Kalender des Geräts übertragen (nur ViviaParms → Kalender)
//
// Über die Kalenderschnittstelle von Android (CalendarContract). Ist der gewählte Kalender einer
// eines Google-Kontos, gleicht Android ihn selbst mit Google Kalender ab – ViviaParms braucht dafür
// weder ein Google-Konto noch Zugangsdaten. Die App (C++) übergibt jeweils den vollständigen Plan
// (JSON); hier wird verglichen: neue Termine eintragen, geänderte ändern, entfallene löschen.
// Welche Kalendereinträge von ViviaParms stammen, steht in den app-eigenen SharedPreferences
// (Schlüssel → Ereignis-ID + Prüfsumme); andere Einträge im Kalender werden nie angefasst.
// Im Kalender gelöschte oder geänderte Einträge werden beim nächsten Übertragen wiederhergestellt.
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
package de.mbergmann.viviaparms;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.CalendarContract;

import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.json.JSONArray;
import org.json.JSONObject;

public class CalendarExport {
    static final String PREFS = "viviaparms_calendar";
    static final String KEY_MAP = "map";        // {"a123": {"ev": 4711, "h": "…"}, …}
    static final String KEY_CAL = "calendar";   // Kalender, in den zuletzt übertragen wurde
    static final String KEY_STATUS = "status";  // {"at": ms, "total": n, "ins": n, "upd": n, "del": n, "error": "…"}
    static final String[] PERMS = { "android.permission.READ_CALENDAR", "android.permission.WRITE_CALENDAR" };
    // Kalenderzugriffe dauern: nie im Oberflächen-Thread, immer nacheinander
    private static final ExecutorService WORKER = Executors.newSingleThreadExecutor();

    public static boolean permissionGranted(Context ctx) {
        if (Build.VERSION.SDK_INT < 23) return true;
        for (String p : PERMS)
            if (ctx.checkSelfPermission(p) != PackageManager.PERMISSION_GRANTED) return false;
        return true;
    }

    public static boolean ensurePermission(Context ctx) {
        if (permissionGranted(ctx)) return true;
        if (ctx instanceof Activity) ((Activity) ctx).requestPermissions(PERMS, 4712);
        return false;
    }

    // Kalender, in die geschrieben werden darf: [{"id", "name", "account", "type", "primary"}]
    public static String calendars(Context ctx) {
        JSONArray out = new JSONArray();
        if (!permissionGranted(ctx)) return out.toString();
        String[] proj = { CalendarContract.Calendars._ID, CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                          CalendarContract.Calendars.ACCOUNT_NAME, CalendarContract.Calendars.ACCOUNT_TYPE,
                          CalendarContract.Calendars.IS_PRIMARY };
        String sel = CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL + ">=? AND " + CalendarContract.Calendars.VISIBLE + "=1";
        try (Cursor c = ctx.getContentResolver().query(CalendarContract.Calendars.CONTENT_URI, proj, sel,
                new String[] { String.valueOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR) },
                CalendarContract.Calendars.ACCOUNT_NAME + "," + CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)) {
            while (c != null && c.moveToNext()) {
                JSONObject o = new JSONObject();
                o.put("id", c.getLong(0));
                o.put("name", c.getString(1) == null ? "" : c.getString(1));
                o.put("account", c.getString(2) == null ? "" : c.getString(2));
                o.put("type", c.getString(3) == null ? "" : c.getString(3));
                o.put("primary", !c.isNull(4) && c.getInt(4) != 0);
                out.put(o);
            }
        } catch (Exception e) {
            // keine Kalender lesbar – leere Liste
        }
        return out.toString();
    }

    public static String status(Context ctx) {
        return ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_STATUS, "{}");
    }

    // Plan übertragen: [{"key", "h", "title", "loc", "desc", "start" (ms), "end" (ms), "allDay", "tz"}]
    public static void sync(final Context ctx, final long calendarId, final String planJson) {
        final Context app = ctx.getApplicationContext();
        WORKER.execute(() -> run(app, calendarId, planJson));
    }

    // Alle übertragenen Einträge wieder entfernen (Option ausgeschaltet)
    public static void clear(final Context ctx) {
        final Context app = ctx.getApplicationContext();
        WORKER.execute(() -> run(app, -1, "[]"));
    }

    private static void run(Context ctx, long calendarId, String planJson) {
        SharedPreferences sp = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        JSONObject st = new JSONObject();
        int ins = 0, upd = 0, del = 0, total = 0;
        try {
            st.put("at", System.currentTimeMillis());
            if (!permissionGranted(ctx)) throw new SecurityException("permission");
            ContentResolver cr = ctx.getContentResolver();
            JSONObject map = new JSONObject(sp.getString(KEY_MAP, "{}"));
            final long oldCal = sp.getLong(KEY_CAL, -1);
            JSONArray plan = new JSONArray(planJson);
            total = plan.length();
            // anderer Kalender gewählt: die Einträge im bisherigen entfernen
            if (oldCal != calendarId) {
                for (Iterator<String> it = map.keys(); it.hasNext(); ) {
                    long ev = map.getJSONObject(it.next()).optLong("ev", -1);
                    if (ev > 0 && cr.delete(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, ev), null, null) > 0) ++del;
                }
                map = new JSONObject();
            }
            Set<String> keep = new HashSet<>();
            for (int i = 0; i < plan.length() && calendarId > 0; ++i) {
                JSONObject p = plan.getJSONObject(i);
                String key = p.getString("key");
                keep.add(key);
                JSONObject known = map.optJSONObject(key);
                long ev = known != null ? known.optLong("ev", -1) : -1;
                boolean alive = ev > 0 && exists(cr, ev, calendarId);
                if (alive && p.getString("h").equals(known.optString("h"))) continue;   // unverändert
                ContentValues v = values(p, calendarId);
                if (alive) {
                    cr.update(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, ev), v, null, null);
                    ++upd;
                } else {
                    Uri u = cr.insert(CalendarContract.Events.CONTENT_URI, v);
                    if (u == null) continue;
                    ev = ContentUris.parseId(u);
                    ++ins;
                }
                JSONObject m = new JSONObject();
                m.put("ev", ev);
                m.put("h", p.getString("h"));
                map.put(key, m);
                if ((ins + upd) % 50 == 0) sp.edit().putString(KEY_MAP, map.toString()).apply();   // Zwischenstand
            }
            // entfallene Termine (gelöscht, außerhalb des Zeitraums, Option aus) entfernen
            JSONArray names = map.names();
            for (int i = 0; names != null && i < names.length(); ++i) {
                String key = names.getString(i);
                if (keep.contains(key)) continue;
                long ev = map.getJSONObject(key).optLong("ev", -1);
                if (ev > 0 && cr.delete(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, ev), null, null) > 0) ++del;
                map.remove(key);
            }
            sp.edit().putString(KEY_MAP, map.toString()).putLong(KEY_CAL, calendarId).apply();
        } catch (SecurityException e) {
            put(st, "error", "permission");
        } catch (Exception e) {
            put(st, "error", String.valueOf(e.getMessage()));
        }
        put(st, "total", total);
        put(st, "ins", ins);
        put(st, "upd", upd);
        put(st, "del", del);
        put(st, "calendar", calendarId);
        sp.edit().putString(KEY_STATUS, st.toString()).apply();
    }

    private static boolean exists(ContentResolver cr, long ev, long calendarId) {
        String[] proj = { CalendarContract.Events.CALENDAR_ID, CalendarContract.Events.DELETED };
        try (Cursor c = cr.query(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, ev), proj, null, null, null)) {
            return c != null && c.moveToFirst() && c.getLong(0) == calendarId && c.getInt(1) == 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static ContentValues values(JSONObject p, long calendarId) throws Exception {
        ContentValues v = new ContentValues();
        v.put(CalendarContract.Events.CALENDAR_ID, calendarId);
        v.put(CalendarContract.Events.TITLE, p.getString("title"));
        v.put(CalendarContract.Events.EVENT_LOCATION, p.optString("loc", ""));
        v.put(CalendarContract.Events.DESCRIPTION, p.optString("desc", ""));
        v.put(CalendarContract.Events.DTSTART, p.getLong("start"));
        v.put(CalendarContract.Events.DTEND, p.getLong("end"));
        boolean allDay = p.optBoolean("allDay", false);
        v.put(CalendarContract.Events.ALL_DAY, allDay ? 1 : 0);
        // ganztägig: Android verlangt UTC-Mitternacht und die Zeitzone UTC
        v.put(CalendarContract.Events.EVENT_TIMEZONE, allDay ? "UTC" : p.optString("tz", java.util.TimeZone.getDefault().getID()));
        v.put(CalendarContract.Events.AVAILABILITY, CalendarContract.Events.AVAILABILITY_BUSY);
        return v;
    }

    private static void put(JSONObject o, String k, Object v) {
        try { o.put(k, v); } catch (Exception ignored) { }
    }
}
