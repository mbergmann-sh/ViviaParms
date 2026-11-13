// ViviaParms Tablet – nach einem Neustart (oder Update) die gestellten Erinnerungen wiederherstellen
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
package de.mbergmann.viviaparms;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context ctx, Intent intent) {
        Reminders.restore(ctx);
    }
}
