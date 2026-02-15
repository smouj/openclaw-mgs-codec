#!/bin/bash

echo "🦞 OpenClaw MGS Codec Dashboard - Test de Integración"
echo "======================================================"
echo ""

# Test 1: Backend Health
echo "✓ Test 1: Backend Health Check"
HEALTH=$(curl -s http://localhost:8001/api/health)
echo "   Response: $HEALTH"
echo ""

# Test 2: Agents List
echo "✓ Test 2: Listado de Agentes"
AGENTS=$(curl -s http://localhost:8001/api/agents | python3 -c "import sys, json; data=json.load(sys.stdin); print(f'   Found {len(data)} agents')")
echo "$AGENTS"
echo ""

# Test 3: Metrics
echo "✓ Test 3: Métricas del Sistema"
METRICS=$(curl -s http://localhost:8001/api/metrics | python3 -c "import sys, json; data=json.load(sys.stdin); print(f'   Active agents: {data[\"active_agents\"]}, Tokens/min: {data[\"tokens_per_minute\"]}')")
echo "$METRICS"
echo ""

# Test 4: Config
echo "✓ Test 4: Configuración"
CONFIG=$(curl -s http://localhost:8001/api/config)
echo "   Response: $CONFIG"
echo ""

# Test 5: Frontend
echo "✓ Test 5: Frontend Status"
FRONTEND=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$FRONTEND" = "200" ]; then
    echo "   Frontend: ✓ ONLINE (HTTP $FRONTEND)"
else
    echo "   Frontend: ✗ OFFLINE (HTTP $FRONTEND)"
fi
echo ""

# Test 6: MongoDB
echo "✓ Test 6: MongoDB Connection"
MONGO_STATUS=$(sudo supervisorctl status mongodb | grep RUNNING)
if [ -n "$MONGO_STATUS" ]; then
    echo "   MongoDB: ✓ RUNNING"
else
    echo "   MongoDB: ✗ NOT RUNNING"
fi
echo ""

echo "======================================================"
echo "FREQUENCY 187.89 MHz - CODEC INTEGRATION TEST COMPLETE"
echo "======================================================"
