// ViviaParms Tablet – zeigt eine Termin-Erinnerung, wenn ihr Wecker abläuft
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
package de.mbergmann.viviaparms;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class ReminderReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context ctx, Intent intent) {
        Reminders.show(ctx, intent.getIntExtra("id", 0), intent.getStringExtra("title"),
                       intent.getStringExtra("text"), intent.getStringExtra("publicText"),
                       intent.getBooleanExtra("sound", true));
    }
}
