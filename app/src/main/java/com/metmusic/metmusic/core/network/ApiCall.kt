package com.metmusic.metmusic.core.network

/**
 * Ejecuta una llamada de Retrofit y normaliza cualquier fallo a [ApiException].
 *
 * `CancellationException` se re-lanza sin envolver: cancelar un job (debounce,
 * cambio de pestaña) no es un error de red y la UI no debe mostrarlo.
 */
suspend fun <T> apiCall(block: suspend () -> T): T =
    try {
        block()
    } catch (e: kotlinx.coroutines.CancellationException) {
        throw e
    } catch (e: retrofit2.HttpException) {
        throw ApiException.fromThrowable(e)
    } catch (e: java.io.IOException) {
        throw ApiException.fromThrowable(e)
    } catch (e: Throwable) {
        throw ApiException.fromThrowable(e)
    }
