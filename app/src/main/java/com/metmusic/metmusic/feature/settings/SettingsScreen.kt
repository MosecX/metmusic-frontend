package com.metmusic.metmusic.feature.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.HealthServiceStatus
import com.metmusic.metmusic.core.network.ApiConstants
import com.metmusic.metmusic.core.ui.components.MetMusicDivider
import com.metmusic.metmusic.core.ui.components.MetMusicListItem
import com.metmusic.metmusic.core.ui.components.MetMusicSectionHeader
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme
import com.metmusic.metmusic.feature.settings.components.QualitySelectorDialog
import com.metmusic.metmusic.feature.settings.components.label
import kotlin.math.roundToInt

/**
 * Ajustes reales (6D): calidad de audio editable (tap aplica), estado de
 * los servicios con refresh, limpieza de la caché del servidor, tema
 * read-only y "Acerca de" (versión + backend). El token nunca se muestra.
 */
@Composable
fun SettingsScreen(
    modifier: Modifier = Modifier,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var showQualityDialog by remember { mutableStateOf(false) }
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(state.actionMessage) {
        val message = state.actionMessage
        if (message != null) {
            snackbarHostState.showSnackbar(message)
            viewModel.dismissActionMessage()
        }
    }

    SettingsScreenContent(
        state = state,
        snackbarHostState = snackbarHostState,
        onQualityRowClick = { showQualityDialog = true },
        onRefreshHealth = viewModel::refreshHealth,
        onClearCache = viewModel::clearServerCache,
        modifier = modifier,
    )

    if (showQualityDialog) {
        QualitySelectorDialog(
            current = state.audioQuality,
            onSelect = { quality ->
                viewModel.setQuality(quality)
                showQualityDialog = false
            },
            onDismiss = { showQualityDialog = false },
        )
    }
}

/** Composición pura de Ajustes (sin ViewModel); el dialog vive en [SettingsScreen]. */
@Composable
fun SettingsScreenContent(
    state: SettingsUiState,
    snackbarHostState: SnackbarHostState,
    onQualityRowClick: () -> Unit,
    onRefreshHealth: () -> Unit,
    onClearCache: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MetMusicColors.background),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            Text(
                text = "Ajustes",
                style = MetMusicTextStyles.largeTitle,
                modifier = Modifier.padding(
                    horizontal = spacing.pagePadding,
                    vertical = spacing.md,
                ),
            )

            MetMusicSectionHeader(title = "Reproducción")
            QualityRow(
                current = state.audioQuality,
                onClick = onQualityRowClick,
            )
            MetMusicDivider()

            MetMusicSectionHeader(title = "Apariencia")
            DisabledRow(label = "Tema", value = "Oscuro")
            MetMusicDivider()

            MetMusicSectionHeader(
                title = "Estado de los servicios",
                actionLabel = if (state.isLoadingHealth) null else "Actualizar",
                onAction = if (state.isLoadingHealth) null else onRefreshHealth,
            )
            HealthContent(
                isLoading = state.isLoadingHealth,
                error = state.healthError,
                services = state.healthServices,
                onRetry = onRefreshHealth,
            )
            MetMusicDivider()

            MetMusicSectionHeader(title = "Mantenimiento")
            ActionRow(
                title = "Limpiar caché del servidor",
                isBusy = state.isClearingCache,
                onClick = onClearCache,
            )
            MetMusicDivider()

            MetMusicSectionHeader(title = "Acerca de")
            InfoRow(label = "Versión", value = APP_VERSION)
            InfoRow(label = "Backend", value = ApiConstants.BASE_URL)
            Spacer(modifier = Modifier.height(spacing.listBottomInset))
        }
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}

/** Fila de la calidad actual: abre el selector. */
@Composable
private fun QualityRow(
    current: AudioQualityPreference,
    onClick: () -> Unit,
) {
    MetMusicListItem(
        title = "Calidad de audio",
        subtitle = current.label(),
        onClick = onClick,
    )
}

/** Fila informativa sin acción (tema read-only). */
@Composable
private fun DisabledRow(
    label: String,
    value: String,
) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .alpha(0.5f)
            .padding(horizontal = spacing.pagePadding, vertical = spacing.md),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(text = label, style = MetMusicTextStyles.rowTitle)
        Text(text = value, style = MetMusicTextStyles.rowSubtitle)
    }
}

/** Fila etiqueta/valor de "Acerca de"; la URL puede ocupar 2 líneas. */
@Composable
private fun InfoRow(
    label: String,
    value: String,
) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = spacing.pagePadding, vertical = spacing.md),
    ) {
        Text(text = label, style = MetMusicTextStyles.label)
        Text(
            text = value,
            style = MetMusicTextStyles.body,
            textAlign = TextAlign.End,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier
                .weight(1f)
                .padding(start = spacing.md),
        )
    }
}

/** Fila de mantenimiento: clickeable salvo mientras corre la acción. */
@Composable
private fun ActionRow(
    title: String,
    isBusy: Boolean,
    onClick: () -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (isBusy) Modifier else Modifier.clickable(onClick = onClick))
            .padding(horizontal = spacing.pagePadding, vertical = spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = MetMusicTextStyles.rowTitle,
            modifier = Modifier.weight(1f),
        )
        if (isBusy) {
            CircularProgressIndicator(
                modifier = Modifier.size(16.dp),
                color = MetMusicColors.accent,
                strokeWidth = 2.dp,
            )
        }
    }
}

/** Estado de los servicios: spinner inicial, error inline con retry o lista. */
@Composable
private fun HealthContent(
    isLoading: Boolean,
    error: String?,
    services: List<HealthServiceStatus>,
    onRetry: () -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    when {
        isLoading && services.isEmpty() -> Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            contentAlignment = Alignment.Center,
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                color = MetMusicColors.accent,
                strokeWidth = 2.dp,
            )
        }
        error != null -> Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = spacing.pagePadding, vertical = spacing.sm),
        ) {
            Text(text = error, style = MetMusicTextStyles.body)
            TextButton(
                onClick = onRetry,
                colors = ButtonDefaults.textButtonColors(contentColor = MetMusicColors.accent),
            ) {
                Text(
                    text = "Reintentar",
                    style = MetMusicTextStyles.button.copy(color = Color.Unspecified),
                )
            }
        }
        services.isEmpty() -> Text(
            text = "Sin datos del backend",
            style = MetMusicTextStyles.bodyLight,
            modifier = Modifier.padding(horizontal = spacing.pagePadding, vertical = spacing.sm),
        )
        else -> Column(modifier = Modifier.fillMaxWidth()) {
            services.forEach { service -> HealthServiceRow(service = service) }
        }
    }
}

/** Fila de un servicio: punto de estado, nombre, latencia y veredicto. */
@Composable
private fun HealthServiceRow(service: HealthServiceStatus) {
    val spacing = LocalMetMusicSpacing.current
    val statusColor = if (service.ok) MetMusicColors.success else MetMusicColors.danger
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = spacing.pagePadding, vertical = spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .background(color = statusColor, shape = CircleShape),
        )
        Spacer(modifier = Modifier.width(spacing.md))
        Text(
            text = service.name,
            style = MetMusicTextStyles.rowTitle,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = latencyLabel(service.latencyMs),
            style = MetMusicTextStyles.rowTrailing,
        )
        Spacer(modifier = Modifier.width(spacing.md))
        Text(
            text = if (service.ok) "OK" else "Error",
            style = MetMusicTextStyles.label,
            color = statusColor,
        )
    }
}

/** Latencia legible: "42 ms" o "—" cuando el backend no la reporta. */
private fun latencyLabel(latencyMs: Double?): String =
    latencyMs?.let { "${it.roundToInt()} ms" } ?: "—"

/**
 * Versión mostrada en Ajustes. `ApiConstants` no expone `APP_VERSION` y el
 * modulo no habilita `BuildConfig` (6A-2), así que se usa el literal que
 * coincide con `metmusic.versionName` de `gradle.properties`.
 */
private const val APP_VERSION = "0.1.0-native"

/** Wrapper de previews: estado de muestra + callbacks no-op. */
@Composable
private fun SettingsContentPreview(state: SettingsUiState) {
    MetMusicTheme {
        SettingsScreenContent(
            state = state,
            snackbarHostState = remember { SnackbarHostState() },
            onQualityRowClick = { /* no-op en preview */ },
            onRefreshHealth = { /* no-op en preview */ },
            onClearCache = { /* no-op en preview */ },
        )
    }
}

@Preview(name = "SettingsScreenContent", showBackground = true, backgroundColor = 0xFF000000, heightDp = 900)
@Composable
private fun SettingsScreenContentPreview() {
    SettingsContentPreview(SettingsUiState.preview())
}

@Preview(
    name = "SettingsScreenContent · health",
    showBackground = true,
    backgroundColor = 0xFF000000,
    heightDp = 900,
)
@Composable
private fun SettingsScreenContentPreviewWithHealth() {
    SettingsContentPreview(SettingsUiState.previewWithHealth())
}

@Preview(
    name = "SettingsScreenContent · health error",
    showBackground = true,
    backgroundColor = 0xFF000000,
    heightDp = 900,
)
@Composable
private fun SettingsScreenContentPreviewHealthError() {
    SettingsContentPreview(
        SettingsUiState.preview().copy(healthError = "No se pudo consultar el estado"),
    )
}
