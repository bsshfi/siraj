package com.wamdarc.siraj;

import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {

    /**
     * نخفي أزرار التنقّل حق الأندرويد (الرجوع، الدائرة، القائمة) عشان التطبيق ياخذ الشاشة كاملة.
     * المستخدم يقدر يظهرها مؤقتًا بالسحب من طرف الشاشة، وترجع تختفي لحالها بعد ثواني.
     * شريط الحالة (الساعة والبطارية) يبقى ظاهر بلون التطبيق.
     */
    private void hideNavigationBar() {
        WindowInsetsControllerCompat c = WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        c.setSystemBarsBehavior(WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        c.hide(WindowInsetsCompat.Type.navigationBars());
    }

    @Override
    public void onResume() {
        super.onResume();
        hideNavigationBar();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideNavigationBar();
    }
}
