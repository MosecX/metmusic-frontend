package com.metmusic.metmusic.core.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.tooling.preview.Preview
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme
import com.metmusic.metmusic.navigation.Routes

/** Tabs top-level del shell de MetMusic. */
enum class MetMusicTab(
    val route: Routes,
    val label: String,
    val icon: ImageVector,
) {
    HOME(Routes.Home, "Home", Icons.Filled.Home),
    SEARCH(Routes.Search, "Buscar", Icons.Filled.Search),
    LIBRARY(Routes.Library, "Biblioteca", Icons.AutoMirrored.Filled.List),
    SETTINGS(Routes.Settings, "Ajustes", Icons.Filled.Settings),
}

/**
 * Bottom bar del shell: cuatro tabs con el acento del tema en el
 * seleccionado. El touch target de [NavigationBarItem] es 48 dp por diseño
 * de Material 3.
 */
@Composable
fun MetMusicBottomBar(
    currentTab: MetMusicTab,
    onTabSelected: (MetMusicTab) -> Unit,
    modifier: Modifier = Modifier,
) {
    NavigationBar(
        modifier = modifier,
        containerColor = MetMusicColors.background,
        contentColor = MetMusicColors.textPrimary,
    ) {
        MetMusicTab.entries.forEach { tab ->
            val selected = currentTab == tab
            NavigationBarItem(
                selected = selected,
                onClick = { if (!selected) onTabSelected(tab) },
                icon = {
                    Icon(
                        imageVector = tab.icon,
                        contentDescription = tab.label,
                    )
                },
                label = {
                    Text(
                        text = tab.label,
                        style = MetMusicTextStyles.label,
                    )
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = MetMusicColors.accent,
                    selectedTextColor = MetMusicColors.accent,
                    indicatorColor = MetMusicColors.accent.copy(alpha = 0.15f),
                    unselectedIconColor = MetMusicColors.textSecondary,
                    unselectedTextColor = MetMusicColors.textSecondary,
                ),
            )
        }
    }
}

@Preview(name = "MetMusicBottomBar tab Home", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicBottomBarHomePreview() {
    MetMusicTheme {
        MetMusicBottomBar(
            currentTab = MetMusicTab.HOME,
            onTabSelected = { /* no-op en preview */ },
        )
    }
}

@Preview(
    name = "MetMusicBottomBar tab Biblioteca",
    showBackground = true,
    backgroundColor = 0xFF000000,
)
@Composable
private fun MetMusicBottomBarLibraryPreview() {
    MetMusicTheme {
        MetMusicBottomBar(
            currentTab = MetMusicTab.LIBRARY,
            onTabSelected = { /* no-op en preview */ },
        )
    }
}
