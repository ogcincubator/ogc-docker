LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'handlers': {
        'stream': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['stream'],
            'level': 'DEBUG',
            'propagate': True,
        },
    },
}
