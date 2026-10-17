package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.tooling.preview.Preview
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Campo de texto de MetMusic: contenedor `controlFill`, borde `glassBorder`,
 * cursor de acento e iconos opcionales (lupa y limpiar).
 */
@Composable
fun MetMusicTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    singleLine: Boolean = true,
    leadingIcon: ImageVector? = null,
    trailingIcon: ImageVector? = null,
    onTrailingIconClick: (() -> Unit)? = null,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier,
        singleLine = singleLine,
        textStyle = MetMusicTextStyles.body,
        placeholder = placeholder.takeIf { it.isNotEmpty() }?.let { text ->
            {
                Text(
                    text = text,
                    style = MetMusicTextStyles.bodyLight,
                )
            }
        },
        leadingIcon = leadingIcon?.let { icon ->
            {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MetMusicColors.textSecondary,
                )
            }
        },
        trailingIcon = trailingIcon?.let { icon ->
            {
                if (onTrailingIconClick != null) {
                    IconButton(onClick = onTrailingIconClick) {
                        Icon(
                            imageVector = icon,
                            contentDescription = null,
                            tint = MetMusicColors.textSecondary,
                        )
                    }
                } else {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = MetMusicColors.textSecondary,
                    )
                }
            }
        },
        shape = RoundedCornerShape(LocalMetMusicRadius.current.md),
        keyboardOptions = keyboardOptions,
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = MetMusicColors.controlFill,
            unfocusedContainerColor = MetMusicColors.controlFill,
            disabledContainerColor = MetMusicColors.controlFill,
            focusedBorderColor = MetMusicColors.glassBorder,
            unfocusedBorderColor = MetMusicColors.glassBorder,
            disabledBorderColor = MetMusicColors.glassBorder,
            focusedTextColor = MetMusicColors.textPrimary,
            unfocusedTextColor = MetMusicColors.textPrimary,
            disabledTextColor = MetMusicColors.textDisabled,
            cursorColor = MetMusicColors.accent,
        ),
    )
}

@Preview(name = "MetMusicTextField con texto", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicTextFieldFilledPreview() {
    MetMusicTheme {
        MetMusicTextField(
            value = "daft punk",
            onValueChange = {},
            modifier = Modifier.padding(LocalMetMusicSpacing.current.lg),
            placeholder = "Buscar en MetMusic",
            leadingIcon = Icons.Filled.Search,
            trailingIcon = Icons.Filled.Close,
            onTrailingIconClick = { /* no-op en preview */ },
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        )
    }
}

@Preview(name = "MetMusicTextField vacío", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicTextFieldEmptyPreview() {
    MetMusicTheme {
        MetMusicTextField(
            value = "",
            onValueChange = {},
            modifier = Modifier.padding(LocalMetMusicSpacing.current.lg),
            placeholder = "Buscar en MetMusic",
            leadingIcon = Icons.Filled.Search,
        )
    }
}
