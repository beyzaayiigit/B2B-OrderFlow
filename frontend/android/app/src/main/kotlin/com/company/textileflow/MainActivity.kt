package com.company.textileflow

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode

class MainActivity : FlutterActivity() {
    /// Bazı Android emülatörlerde Surface + Skia/Impeller ilk karede siyah ekran
    /// verebiliyor; texture genelde daha stabil.
    override fun getRenderMode(): RenderMode = RenderMode.texture

    override fun getTransparencyMode(): TransparencyMode = TransparencyMode.opaque
}
