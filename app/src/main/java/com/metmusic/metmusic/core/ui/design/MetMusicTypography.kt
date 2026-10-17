package com.metmusic.metmusic.core.ui.design

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.metmusic.metmusic.R

/**
 * Familia Inter bundleada (pesos 300–700). El diseño usa light, regular,
 * medium, semibold y bold.
 */
val MetMusicFontFamily = FontFamily(
    Font(R.font.inter_light, FontWeight.Light),
    Font(R.font.inter_regular, FontWeight.Normal),
    Font(R.font.inter_medium, FontWeight.Medium),
    Font(R.font.inter_semibold, FontWeight.SemiBold),
    Font(R.font.inter_bold, FontWeight.Bold),
)

/** Tipografías de MetMusic, portadas 1:1 desde AppTextStyles (Flutter). */
object MetMusicTextStyles {

    /** Título grande de pantalla (34 / 700 / -0.6, estilo Apple large title). */
    val display: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 34.sp,
        fontWeight = FontWeight.W700,
        color = MetMusicColors.textPrimary,
        letterSpacing = (-0.6).sp,
        lineHeight = 37.4.sp,
    )

    /** Alias de display, igual que en Flutter. */
    val largeTitle: TextStyle = display

    val headline: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 24.sp,
        fontWeight = FontWeight.W700,
        color = MetMusicColors.textPrimary,
        letterSpacing = (-0.4).sp,
    )

    /** Título de sección (22 / 700 / -0.4). */
    val sectionTitle: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 22.sp,
        fontWeight = FontWeight.W700,
        color = MetMusicColors.textPrimary,
        letterSpacing = (-0.4).sp,
    )

    val title: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 18.sp,
        fontWeight = FontWeight.W600,
        color = MetMusicColors.textPrimary,
    )

    val subtitle: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 15.sp,
        fontWeight = FontWeight.Normal,
        color = MetMusicColors.textSecondary,
    )

    val body: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 14.sp,
        fontWeight = FontWeight.Normal,
        color = MetMusicColors.textPrimary,
    )

    val bodyLight: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 14.sp,
        fontWeight = FontWeight.Light,
        color = MetMusicColors.textSecondary,
    )

    val label: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 12.sp,
        fontWeight = FontWeight.W600,
        color = MetMusicColors.textSecondary,
        letterSpacing = 0.4.sp,
    )

    val caption: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 11.sp,
        fontWeight = FontWeight.Normal,
        color = MetMusicColors.textTertiary,
    )

    val overline: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 11.sp,
        fontWeight = FontWeight.W700,
        color = MetMusicColors.textTertiary,
        letterSpacing = 1.2.sp,
    )

    val button: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 14.sp,
        fontWeight = FontWeight.W600,
        color = MetMusicColors.textPrimary,
    )

    /** Título de card (15 / 600), carruseles y tiles. */
    val cardTitle: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 15.sp,
        fontWeight = FontWeight.W600,
        color = MetMusicColors.textPrimary,
        lineHeight = 18.75.sp,
    )

    /** Subtítulo de card / meta (13 / 400, secundario). */
    val cardSubtitle: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 13.sp,
        fontWeight = FontWeight.Normal,
        color = MetMusicColors.textSecondary,
    )

    /** Título de fila (16 / 500). */
    val rowTitle: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 16.sp,
        fontWeight = FontWeight.Medium,
        color = MetMusicColors.textPrimary,
    )

    /** Subtítulo de fila (13.5 / 400, secundario). */
    val rowSubtitle: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 13.5.sp,
        fontWeight = FontWeight.Normal,
        color = MetMusicColors.textSecondary,
    )

    /** Duración / valores tabulares (13.5 / 400, terciario). */
    val rowTrailing: TextStyle = TextStyle(
        fontFamily = MetMusicFontFamily,
        fontSize = 13.5.sp,
        fontWeight = FontWeight.Normal,
        color = MetMusicColors.textTertiary,
        fontFeatureSettings = "tnum",
    )
}

/** Estilos de MetMusic mapeados a los slots de Material 3. */
val MetMusicTypography = Typography(
    displayLarge = MetMusicTextStyles.display,
    displayMedium = MetMusicTextStyles.display,
    displaySmall = MetMusicTextStyles.display,
    headlineLarge = MetMusicTextStyles.headline,
    headlineMedium = MetMusicTextStyles.sectionTitle,
    headlineSmall = MetMusicTextStyles.sectionTitle,
    titleLarge = MetMusicTextStyles.title,
    titleMedium = MetMusicTextStyles.rowTitle,
    titleSmall = MetMusicTextStyles.cardTitle,
    bodyLarge = MetMusicTextStyles.body,
    bodyMedium = MetMusicTextStyles.subtitle,
    bodySmall = MetMusicTextStyles.cardSubtitle,
    labelLarge = MetMusicTextStyles.button,
    labelMedium = MetMusicTextStyles.label,
    labelSmall = MetMusicTextStyles.caption,
)
