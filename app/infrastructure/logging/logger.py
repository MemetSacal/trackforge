import structlog
import logging


def setup_logging():
    # Uygulama başlangıcında bir kere çağrılır, tüm log ayarlarını konfigure eder
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,           # Log seviyesi filtresi (INFO, WARNING, ERROR)
            structlog.stdlib.add_logger_name,            # Log kaynağının adını ekler
            structlog.stdlib.add_log_level,              # Log seviyesini ekler
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"), # ISO format timestamp ekler
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,        # Exception detaylarını formatlar
            structlog.processors.JSONRenderer(),         # Her log satırını JSON formatına çevirir
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,                  # Performans için logger'ı cache'ler
    )
    logging.basicConfig(level=logging.INFO)


# Proje genelinde kullanılacak logger — her dosyada import edilir
logger = structlog.get_logger()