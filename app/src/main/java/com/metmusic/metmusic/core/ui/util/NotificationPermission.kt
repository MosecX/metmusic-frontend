package com.metmusic.metmusic.core.ui.util

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * Consultas del permiso POST_NOTIFICATIONS (runtime desde API 33).
 *
 * La lógica pura ([isGranted] y [shouldRequest] con `sdkInt` + estado del
 * permiso) es testeable en JVM; los wrappers con [Context] delegan en ella
 * leyendo los valores reales del dispositivo. `TIRAMISU_INT` espeja
 * `Build.VERSION_CODES.TIRAMISU` para no depender de la constante de Android
 * en la lógica pura.
 */
object NotificationPermission {

    /** Primera API que exige POST_NOTIFICATIONS en runtime (33). */
    private const val TIRAMISU_INT = 33

    /** True si la app puede postear notificaciones; en API < 33 siempre true. */
    fun isGranted(sdkInt: Int, permissionGranted: Boolean): Boolean {
        if (sdkInt < TIRAMISU_INT) return true
        return permissionGranted
    }

    /** True si hay que pedir el permiso (API 33+ y no otorgado). */
    fun shouldRequest(sdkInt: Int, permissionGranted: Boolean): Boolean =
        !isGranted(sdkInt, permissionGranted)

    /** True si la app puede postear notificaciones en este dispositivo. */
    fun isGranted(context: Context): Boolean =
        isGranted(
            sdkInt = Build.VERSION.SDK_INT,
            permissionGranted = isPostNotificationsGranted(context),
        )

    /** True si el sistema exige pedir POST_NOTIFICATIONS y aún no está otorgado. */
    fun shouldRequest(context: Context): Boolean = !isGranted(context)

    private fun isPostNotificationsGranted(context: Context): Boolean =
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
}
