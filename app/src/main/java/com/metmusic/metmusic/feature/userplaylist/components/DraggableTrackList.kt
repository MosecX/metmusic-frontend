package com.metmusic.metmusic.feature.userplaylist.components

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Lista editable de una playlist propia (6E-2) con reorder por drag & drop y
 * remove por fila.
 *
 * El drag se implementa solo con APIs de Compose Foundation: long press sobre
 * el handle, seguimiento del offset con [graphicsLayer] y swap con el vecino
 * cuando el desplazamiento supera media altura de la fila. La fila arrastrada
 * se identifica por `trackId` (no por índice) para que el gesto sobreviva a
 * los reorders que el ViewModel aplica de forma optimista.
 */
@Composable
fun DraggableTrackList(
    tracks: List<Track>,
    onMove: (from: Int, to: Int) -> Unit,
    onRemove: (trackId: String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    val listState = rememberLazyListState()
    val currentTracks by rememberUpdatedState(tracks)
    val currentOnMove by rememberUpdatedState(onMove)
    var draggingTrackId by remember { mutableStateOf<String?>(null) }
    var dragOffset by remember { mutableFloatStateOf(0f) }
    val itemHeights = remember { mutableStateMapOf<String, Int>() }

    LazyColumn(
        state = listState,
        modifier = modifier.fillMaxSize(),
    ) {
        itemsIndexed(tracks, key = { _, track -> track.trackId }) { _, track ->
            val isDragging = draggingTrackId == track.trackId
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .zIndex(if (isDragging) 1f else 0f)
                    .then(if (isDragging) Modifier else Modifier.animateItem())
                    .graphicsLayer { translationY = if (isDragging) dragOffset else 0f }
                    .onGloballyPositioned { coordinates ->
                        itemHeights[track.trackId] = coordinates.size.height
                    },
            ) {
                TrackReorderRow(
                    track = track,
                    onRemove = { onRemove(track.trackId) },
                    dragHandleModifier = Modifier.pointerInput(track.trackId) {
                        detectDragGesturesAfterLongPress(
                            onDragStart = {
                                draggingTrackId = track.trackId
                                dragOffset = 0f
                            },
                            onDrag = { change, dragAmount ->
                                change.consume()
                                val current = currentTracks
                                val currentIndex = current.indexOfFirst { item ->
                                    item.trackId == track.trackId
                                }
                                if (currentIndex != -1) {
                                    dragOffset += dragAmount.y
                                    val rowHeight = (itemHeights[track.trackId]
                                        ?: DEFAULT_ITEM_HEIGHT_PX).toFloat()
                                    if (dragOffset > rowHeight / 2f &&
                                        currentIndex < current.lastIndex
                                    ) {
                                        currentOnMove(currentIndex, currentIndex + 1)
                                        dragOffset -= rowHeight
                                    } else if (dragOffset < -rowHeight / 2f &&
                                        currentIndex > 0
                                    ) {
                                        currentOnMove(currentIndex, currentIndex - 1)
                                        dragOffset += rowHeight
                                    }
                                }
                            },
                            onDragEnd = {
                                draggingTrackId = null
                                dragOffset = 0f
                            },
                            onDragCancel = {
                                draggingTrackId = null
                                dragOffset = 0f
                            },
                        )
                    },
                )
            }
        }
        item {
            Spacer(modifier = Modifier.height(spacing.listBottomInset))
        }
    }
}

/** Fila de la lista editable: handle de drag, título/artista y trash. */
@Composable
private fun TrackReorderRow(
    track: Track,
    onRemove: () -> Unit,
    dragHandleModifier: Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = spacing.lg, vertical = spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = dragHandleModifier.size(48.dp),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.Filled.Menu,
                contentDescription = "Arrastrar para reordenar",
                tint = MetMusicColors.textSecondary,
            )
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = track.displayTitle,
                style = MetMusicTextStyles.rowTitle,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            track.artist?.takeIf { it.isNotBlank() }?.let { artist ->
                Text(
                    text = artist,
                    style = MetMusicTextStyles.rowSubtitle,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        IconButton(onClick = onRemove) {
            Icon(
                imageVector = Icons.Filled.Delete,
                contentDescription = "Quitar de la playlist",
                tint = MetMusicColors.textSecondary,
            )
        }
    }
}

/** Altura de respaldo mientras `onGloballyPositioned` no midió la fila. */
private const val DEFAULT_ITEM_HEIGHT_PX = 64

private val previewTracks: List<Track> = listOf(
    Track(trackId = "preview-drag-1", title = "One More Time", artist = "Daft Punk"),
    Track(trackId = "preview-drag-2", title = "Around the World", artist = "Daft Punk"),
    Track(trackId = "preview-drag-3", title = "Instant Crush", artist = "Daft Punk"),
    Track(trackId = "preview-drag-4", title = "Get Lucky", artist = "Daft Punk"),
)

@Preview(
    name = "DraggableTrackList",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 420,
)
@Composable
private fun DraggableTrackListPreview() {
    MetMusicTheme {
        DraggableTrackList(
            tracks = previewTracks,
            onMove = { _, _ -> /* no-op en preview */ },
            onRemove = { /* no-op en preview */ },
            modifier = Modifier
                .fillMaxSize()
                .background(MetMusicColors.background),
        )
    }
}
