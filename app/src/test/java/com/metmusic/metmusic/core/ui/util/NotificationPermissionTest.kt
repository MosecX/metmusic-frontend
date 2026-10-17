package com.metmusic.metmusic.core.ui.util

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class NotificationPermissionTest {

    private companion object {
        /** Última API que no exige POST_NOTIFICATIONS en runtime. */
        const val BELOW_TIRAMISU = 32

        /** Primera API que exige POST_NOTIFICATIONS en runtime. */
        const val TIRAMISU = 33
    }

    @Test
    fun `isGranted below API 33 regardless of the permission`() {
        assertTrue(NotificationPermission.isGranted(sdkInt = 30, permissionGranted = true))
        assertTrue(NotificationPermission.isGranted(sdkInt = BELOW_TIRAMISU, permissionGranted = false))
    }

    @Test
    fun `isGranted with the permission from API 33`() {
        assertTrue(NotificationPermission.isGranted(sdkInt = TIRAMISU, permissionGranted = true))
    }

    @Test
    fun `isGranted requires the permission from API 33`() {
        assertFalse(NotificationPermission.isGranted(sdkInt = TIRAMISU, permissionGranted = false))
    }

    @Test
    fun `shouldRequest is the inverse of isGranted`() {
        assertFalse(NotificationPermission.shouldRequest(sdkInt = BELOW_TIRAMISU, permissionGranted = false))
        assertTrue(NotificationPermission.shouldRequest(sdkInt = TIRAMISU, permissionGranted = false))
        assertFalse(NotificationPermission.shouldRequest(sdkInt = TIRAMISU, permissionGranted = true))
    }
}
