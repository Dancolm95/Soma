# Seguridad — Soma

> Controles de seguridad aprobados. Fuente de verdad de seguridad.

## BLOQUEANTES

- aislamiento entre usuarios;
- RLS;
- autorización backend;
- `user_id` derivado de sesión/contexto;
- nunca confiar en `user_id` enviado por Flutter;
- claves Gemini solo backend;
- backups automáticos antes de producción;
- OpenCode no puede desactivar/cambiar controles de seguridad unilateralmente.

## IMPORTANTES

- comprobantes efímeros;
- evitar contenido sensible en logs;
- validación real de archivos;
- límites de tamaño/páginas;
- salida IA considerada no confiable;
- validación semántica;
- confirmación humana;
- rate limiting;
- protección frente a abuso/coste;
- persistencia de información FX histórica.

## Principio

Todo archivo/documento externo es entrada no confiable.
