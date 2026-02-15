# 🔧 OpenClaw Integration Guide

## Descripción General

Este dashboard está diseñado para integrarse con la API de OpenClaw para orquestación de agentes multi-modelo. La integración actual es un framework base que puede ser personalizado según tus necesidades específicas.

---

## 📡 Configuración de OpenClaw API

### Obtener tu Token

1. Visita el sitio web de OpenClaw
2. Crea una cuenta o inicia sesión
3. Ve a la sección de API keys
4. Genera un nuevo token con los permisos necesarios
5. Copia el token (formato: `openclaw_xxxxxxxxxxxxxxxx`)

### Configurar el Token en el Dashboard

1. Abre el dashboard en tu navegador
2. Haz clic en el botón **🔒 TOKEN** en la barra inferior
3. Pega tu token de OpenClaw
4. Haz clic en **SAVE TOKEN**
5. El token será encriptado y almacenado de forma segura

---

## 🔌 Endpoints de la API

### Backend API Endpoints

El backend proporciona los siguientes endpoints para interactuar con OpenClaw:

#### Health Check
```bash
GET /api/health
```
Respuesta:
```json
{
  "status": "operational",
  "frequency": "187.89 MHz",
  "codec": "active"
}
```

#### Lista de Agentes
```bash
GET /api/agents
```
Respuesta: Array de agentes con sus configuraciones

#### Crear Conversación
```bash
POST /api/conversations?agent_id={agent_id}&title={title}
```

#### Enviar Mensaje
```bash
POST /api/conversations/{conversation_id}/messages?role=user&content={message}&agent_id={agent_id}
```

#### Guardar Token
```bash
POST /api/config/token?token={openclaw_token}
```

#### Obtener Métricas
```bash
GET /api/metrics
```

---

## 🛠️ Personalización de la Integración

### Modificar la Función de Llamada a OpenClaw

El archivo `/app/backend/server.py` contiene la función `call_openclaw_agent` que puedes personalizar:

```python
async def call_openclaw_agent(token: str, agent_id: str, message: str) -> str:
    """
    Personaliza esta función según la API de OpenClaw
    """
    try:
        async with httpx.AsyncClient() as client:
            # Ajusta el endpoint según la documentación de OpenClaw
            response = await client.post(
                "https://api.openclaw.ai/v1/chat",  # URL de ejemplo
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json"
                },
                json={
                    "agent_id": agent_id,
                    "message": message,
                    "stream": False
                },
                timeout=30.0
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("response", "Agent response received")
            else:
                return f"[ERROR] OpenClaw API returned status {response.status_code}"
    except Exception as e:
        return f"[ERROR] Failed to contact OpenClaw: {str(e)}"
```

### Parámetros Configurables

Puedes ajustar los siguientes parámetros en la llamada:

- **URL del endpoint**: Cambia la URL según la documentación oficial
- **Headers**: Añade headers adicionales si son necesarios
- **Payload**: Ajusta el formato del JSON según la API
- **Timeout**: Modifica el timeout según tus necesidades
- **Streaming**: Habilita streaming para respuestas en tiempo real

---

## 🔄 Streaming de Respuestas (Opcional)

Si la API de OpenClaw soporta streaming, puedes implementarlo así:

```python
@app.post("/api/conversations/{conversation_id}/messages/stream")
async def send_message_stream(conversation_id: str, role: str, content: str):
    async def event_generator():
        async with httpx.AsyncClient() as client:
            async with client.stream(
                "POST",
                "https://api.openclaw.ai/v1/chat/stream",
                headers={"Authorization": f"Bearer {token}"},
                json={"message": content, "stream": True}
            ) as response:
                async for chunk in response.aiter_text():
                    yield f"data: {chunk}\n\n"
    
    return StreamingResponse(event_generator(), media_type="text/event-stream")
```

---

## 📊 Métricas y Monitoreo

El dashboard rastrea automáticamente:

- **Tokens por minuto**: Calculado desde las respuestas de OpenClaw
- **Costo por hora**: Basado en el uso de tokens (configurable)
- **Agentes activos**: Número de agentes conectados
- **Uso de memoria**: Almacenamiento de conversaciones

### Personalizar Cálculo de Métricas

Edita la función `get_metrics` en `/app/backend/server.py`:

```python
@app.get("/api/metrics", response_model=Metrics)
async def get_metrics():
    # Consulta métricas reales desde MongoDB
    total_conversations = await db.conversations.count_documents({})
    active_agents = await db.agents.count_documents({"status": {"$in": ["connected", "busy"]}})
    
    # Calcula tokens desde las conversaciones recientes
    recent_convs = await db.conversations.find().sort("updated_at", -1).limit(10).to_list(10)
    total_tokens = sum(conv.get("metrics", {}).get("tokens_used", 0) for conv in recent_convs)
    
    # Calcula costo basado en tu pricing de OpenClaw
    cost_per_token = 0.00002  # Ajusta según tu plan
    estimated_cost_per_hour = (total_tokens / 10) * 60 * cost_per_token
    
    metrics = Metrics(
        tokens_per_minute=total_tokens / 10,
        cost_per_hour=estimated_cost_per_hour,
        active_agents=active_agents,
        total_conversations=total_conversations,
        memory_usage=67.8,  # Calcula el uso real de memoria
        uptime="04:23:17"   # Calcula el uptime real
    )
    return metrics
```

---

## 🔐 Seguridad

### Encriptación de Tokens

Los tokens se encriptan usando Fernet de la librería `cryptography`:

```python
from cryptography.fernet import Fernet

# El SECRET_KEY debe ser una clave de 44 caracteres base64
# Genera una nueva: Fernet.generate_key()
SECRET_KEY = os.getenv("SECRET_KEY")
cipher_suite = Fernet(SECRET_KEY.encode())

# Encriptar
encrypted = cipher_suite.encrypt(token.encode()).decode()

# Desencriptar
decrypted = cipher_suite.decrypt(encrypted.encode()).decode()
```

### Variables de Entorno

**IMPORTANTE**: Cambia el `SECRET_KEY` en producción:

```bash
# Generar nueva clave
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Actualizar en /app/backend/.env
SECRET_KEY=nueva_clave_generada_aqui
```

---

## 🧪 Testing

### Pruebas de Integración

```bash
# Ejecutar suite de tests
/app/test_integration.sh

# Test manual de mensajes
curl -X POST "http://localhost:8001/api/conversations" \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "agent-id-here", "title": "Test Call"}'

# Enviar mensaje de prueba
curl -X POST "http://localhost:8001/api/conversations/conv-id/messages" \
  -d "role=user&content=Hello&agent_id=agent-id"
```

### Debugging

```bash
# Ver logs del backend
tail -f /var/log/supervisor/backend.*.log

# Ver errores específicos
grep -i "error" /var/log/supervisor/backend.err.log

# Verificar conexión MongoDB
mongo openclaw_db --eval "db.agents.find().pretty()"
```

---

## 📚 Recursos Adicionales

### Documentación Oficial de OpenClaw
- Website: https://openclaw.ai (ajustar según la URL real)
- API Docs: https://docs.openclaw.ai (ajustar según la URL real)
- Discord: Link a la comunidad
- GitHub: Link al repositorio oficial

### Librerías Utilizadas

**Backend:**
- FastAPI - Framework web
- Motor - Driver async de MongoDB
- Cryptography - Encriptación de tokens
- HTTPx - Cliente HTTP async

**Frontend:**
- React - Framework UI
- Axios - Cliente HTTP
- TailwindCSS - Utilidades CSS

---

## 🐛 Troubleshooting

### Error: "OpenClaw API returned status 401"
- **Solución**: Token inválido o expirado. Genera un nuevo token.

### Error: "Failed to contact OpenClaw"
- **Solución**: Verifica la URL del endpoint y la conectividad de red.

### Error: "Token not configured"
- **Solución**: Configura tu token desde el botón 🔒 TOKEN en el dashboard.

### Frontend no carga
- **Solución**: Verifica que `REACT_APP_BACKEND_URL` esté correctamente configurado en `/app/frontend/.env`

### WebSocket no conecta
- **Solución**: Verifica que el backend esté corriendo y accesible en el puerto 8001.

---

## 💡 Tips y Mejores Prácticas

1. **Rate Limiting**: Implementa rate limiting para evitar sobrecostos
2. **Caching**: Cachea respuestas comunes para reducir llamadas a la API
3. **Error Handling**: Implementa retry logic con exponential backoff
4. **Logging**: Registra todas las llamadas a la API para debugging
5. **Monitoring**: Usa el dashboard de métricas para monitorear uso
6. **Backups**: Haz backups regulares de MongoDB para conservar conversaciones

---

## 🤝 Soporte

Si encuentras problemas con la integración:

1. Revisa los logs del backend
2. Verifica la documentación oficial de OpenClaw
3. Abre un issue en el repositorio
4. Contacta al soporte de OpenClaw para problemas específicos de la API

---

**FREQUENCY 187.89 MHz - INTEGRATION GUIDE COMPLETE** 🦞
