#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# MiPIT PoC — Smoke Test Script
# Validates that all services are up and the critical API paths work.
# Usage: ./smoke-test.sh [BASE_URL]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
  local name="$1"
  local url="$2"
  local expected_status="${3:-200}"
  local body_contains="${4:-}"

  response=$(curl -s -o /tmp/smoke_body -w "%{http_code}" --max-time 10 "$url") || response="000"

  if [ "$response" = "$expected_status" ]; then
    if [ -n "$body_contains" ] && ! grep -q "$body_contains" /tmp/smoke_body; then
      echo -e "  ${RED}FAIL${NC} $name — HTTP $response but body missing: '$body_contains'"
      FAIL=$((FAIL + 1))
    else
      echo -e "  ${GREEN}PASS${NC} $name — HTTP $response"
      PASS=$((PASS + 1))
    fi
  else
    echo -e "  ${RED}FAIL${NC} $name — expected HTTP $expected_status, got $response"
    FAIL=$((FAIL + 1))
  fi
}

check_post() {
  local name="$1"
  local url="$2"
  local body="$3"
  local expected_status="${4:-200}"
  local body_contains="${5:-}"

  response=$(curl -s -o /tmp/smoke_body -w "%{http_code}" \
    --max-time 10 \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$body" \
    "$url") || response="000"

  if [ "$response" = "$expected_status" ] || [ "$response" = "201" ]; then
    if [ -n "$body_contains" ] && ! grep -q "$body_contains" /tmp/smoke_body; then
      echo -e "  ${RED}FAIL${NC} $name — HTTP $response but body missing: '$body_contains'"
      FAIL=$((FAIL + 1))
    else
      echo -e "  ${GREEN}PASS${NC} $name — HTTP $response"
      PASS=$((PASS + 1))
    fi
  else
    echo -e "  ${RED}FAIL${NC} $name — expected HTTP $expected_status/$((expected_status + 1)), got $response"
    cat /tmp/smoke_body 2>/dev/null | head -5 || true
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MiPIT PoC — Smoke Tests"
echo "  Base URL: $BASE_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "${YELLOW}[1/5] Health & Metrics${NC}"
check "GET /health" "$BASE_URL/health" 200 "ok"
check "GET /metrics" "$BASE_URL/metrics" 200 ""

echo ""
echo "${YELLOW}[2/5] Translation Rails Metadata${NC}"
check "GET /translate/rails" "$BASE_URL/translate/rails" 200 "PIX"
check "GET /translate/rails — contains SWIFT" "$BASE_URL/translate/rails" 200 "SWIFT_MT103"
check "GET /translate/rails — contains FEDNOW" "$BASE_URL/translate/rails" 200 "FEDNOW"

echo ""
echo "${YELLOW}[3/5] Translation — PIX → SPEI${NC}"
check_post "POST /translate (PIX→SPEI)" "$BASE_URL/translate" \
  '{"sourceRail":"PIX","destinationRail":"SPEI","payload":{"endToEndId":"E6074694820230601120012345678901","valor":{"original":"1500.00"},"pagador":{"ispb":"60746948","nome":"João Silva","cpf":"12345678901","contaTransacional":{"numero":"123456-7","tipoConta":"CACC"}},"recebedor":{"ispb":"00000000","nome":"Maria Garcia"},"chave":"+5521999887766","tipoChave":"PHONE","tipo":"TRANSF"}}' \
  200 "translated"

echo ""
echo "${YELLOW}[4/5] Translation — SWIFT MT103 → ISO 20022${NC}"
check_post "POST /translate (SWIFT→ISO20022)" "$BASE_URL/translate" \
  '{"sourceRail":"SWIFT_MT103","destinationRail":"ISO20022_MX","payload":{"transactionRef":"TXN001","bankOperationCode":"CRED","valueDate":"2023-06-01","currency":"USD","amount":1500,"orderingCustomer":{"account":"123456789","name":"John Smith","address":["100 Main St"]},"beneficiaryCustomer":{"account":"DEST-ACCT-001","name":"Maria Garcia","address":["Mexico City"]},"detailsOfCharges":"SHA"}}' \
  200 "translated"

echo ""
echo "${YELLOW}[5/5] Translation Preview${NC}"
check_post "POST /translate/preview (FEDNOW)" "$BASE_URL/translate/preview" \
  '{"sourceRail":"FEDNOW","payload":{"FIToFICstmrCdtTrf":{"GrpHdr":{"MsgId":"MSG-001","CreDtTm":"2023-06-01T12:00:00Z","NbOfTxs":"1","SttlmInf":{"SttlmMtd":"CLRG","ClrSys":{"Cd":"USABA"}}},"CdtTrfTxInf":{"PmtId":{"EndToEndId":"E2E-001"},"IntrBkSttlmAmt":{"Ccy":"USD","value":"500.00"},"IntrBkSttlmDt":"2023-06-01","DbtrAgt":{"FinInstnId":{"ClrSysMmbId":{"ClrSysId":{"Cd":"USABA"},"MmbId":"021000021"}}},"Dbtr":{"Nm":"Alice"},"DbtrAcct":{"Id":{"Othr":{"Id":"987654321"}}},"CdtrAgt":{"FinInstnId":{"ClrSysMmbId":{"ClrSysId":{"Cd":"USABA"},"MmbId":"026009593"}}},"Cdtr":{"Nm":"Bob"},"CdtrAcct":{"Id":{"Othr":{"Id":"123456789"}}}}}}}' \
  200 "translations"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Results: ${GREEN}${PASS} passed${NC}  ${RED}${FAIL} failed${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAIL -gt 0 ]; then
  exit 1
fi
