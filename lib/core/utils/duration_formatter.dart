/// Formateo de duraciones para la UI.
class DurationFormatter {
  DurationFormatter._();

  /// `m:ss` para canciones, `h:mm:ss` cuando supera la hora.
  static String format(Duration d) {
    final total = d.inSeconds.abs();
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
    }
    return '$minutes:$ss';
  }

  /// Igual que [format] pero a partir de segundos.
  static String fromSeconds(int seconds) => format(Duration(seconds: seconds));

  /// Formato largo, ej. `1 h 12 min` o `3 min 24 s`.
  static String long(Duration d) {
    final total = d.inSeconds.abs();
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours > 0) return '$hours h ${minutes.toString().padLeft(2, '0')} min';
    if (minutes > 0) return '$minutes min ${total % 60} s';
    return '$total s';
  }

  /// Suma de una lista de duraciones.
  static Duration total(Iterable<Duration> durations) =>
      durations.fold(Duration.zero, (a, b) => a + b);
}
