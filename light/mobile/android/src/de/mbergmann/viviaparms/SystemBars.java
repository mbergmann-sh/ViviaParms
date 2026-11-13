// ViviaParms mobile – Symbole der Status- und Navigationsleiste passend zum Design
// (Android 15+ zeichnet die App bis unter die Leisten; ohne Anpassung stünden im dunklen Design
// dunkle Symbole auf dunklem Grund)
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
package de.mbergmann.viviaparms;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.view.Window;
import android.view.WindowInsetsController;

public class SystemBars {
    // light = true: heller Hintergrund → dunkle Symbole
    public static void setLight(Context ctx, final boolean light) {
        // Nur bei randloser Darstellung (Ziel-API 35+ auf Android 15+): Darunter hat die Statusleiste
        // ihren eigenen (dunklen) Hintergrund – dunkle Symbole wären dort unsichtbar.
        if (Build.VERSION.SDK_INT < 35) return;
        if (!(ctx instanceof Activity)) return;
        final Activity a = (Activity) ctx;
        a.runOnUiThread(() -> apply(a, light));
    }

    private static void apply(Activity a, boolean light) {
        Window w = a.getWindow();
        if (w == null) return;
        WindowInsetsController c = w.getInsetsController();
        if (c == null) return;
        int mask = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
                 | WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS;
        c.setSystemBarsAppearance(light ? mask : 0, mask);
    }
}
