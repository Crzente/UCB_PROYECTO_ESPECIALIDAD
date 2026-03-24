/// Utilidades para manejo de rangos militares
class MilitaryRankUtils {
  // Mapeo de grados a abreviaciones
  static const Map<String, String> gradoAbreviaciones = {
    'Subteniente': 'Sbtte.',
    'Teniente': 'Tte.',
    'Capitán': 'Cap.',
    'Mayor': 'My.',
    'Teniente Coronel': 'Tcnl.',
    'Coronel': 'Cnl.',
    'Sargento Inicial': 'Sgto. Inc.',
    'Sargento Segundo': 'Sgto. 2do.',
    'Sargento Primero': 'Sgto. 1ro.',
    'Suboficial Inicial': 'Sof. Inc.',
    'Suboficial Segundo': 'Sof. 2do.',
    'Suboficial Primero': 'Sof. 1ro.',
    'Suboficial Mayor': 'Sof. My.',
  };

  /// Convierte un grado militar a su abreviación
  /// Si el grado no tiene abreviación definida, retorna el grado original
  static String abreviarGrado(String grado) {
    return gradoAbreviaciones[grado] ?? grado;
  }

  /// Obtiene el escalafón (grupo) al que pertenece un grado
  static String obtenerEscalafon(String grado) {
    const Map<String, String> gradosPorGrupo = {
      'Subteniente': 'Oficiales Superiores y Subalternos',
      'Teniente': 'Oficiales Superiores y Subalternos',
      'Capitán': 'Oficiales Superiores y Subalternos',
      'Mayor': 'Oficiales Superiores y Subalternos',
      'Teniente Coronel': 'Oficiales Superiores y Subalternos',
      'Coronel': 'Oficiales Superiores y Subalternos',
      'Sargento Inicial': 'Suboficiales y Sargentos',
      'Sargento Segundo': 'Suboficiales y Sargentos',
      'Sargento Primero': 'Suboficiales y Sargentos',
      'Suboficial Inicial': 'Suboficiales y Sargentos',
      'Suboficial Segundo': 'Suboficiales y Sargentos',
      'Suboficial Primero': 'Suboficiales y Sargentos',
      'Suboficial Mayor': 'Suboficiales y Sargentos',
    };

    return gradosPorGrupo[grado] ?? '-';
  }
}
