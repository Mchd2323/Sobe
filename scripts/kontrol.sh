#!/bin/bash
# YEREL KONTROL = CI ile AYNI katilikta. Bugun iki kez CI'i kirmamin sebebi
# yerel grep'imin 'ERROR:' satirlarini gormemesiydi.
S=/tmp/claude-0/-home-user-vaaz-asistani/f43a24d4-86ab-5f62-8ea5-a975c16a92bf/scratchpad
G="$S/Godot_v4.7.2-stable_linux.x86_64"
cd "$S/repo" || exit 1
rm -rf .godot
echo "--- 1) parse ---"
"$G" --headless --editor --quit --path . 2>&1 | tee /tmp/k_imp.log >/dev/null
if grep -qE "SCRIPT ERROR|Parse Error" /tmp/k_imp.log; then
  echo "KIRMIZI: parse"; grep -E "SCRIPT ERROR|Parse Error|  at: " /tmp/k_imp.log | head; exit 1; fi
echo "--- 2) smoke (CI ile ayni grep: ERROR: dahil) ---"
timeout 12 "$G" --headless --path . 2>&1 | tee /tmp/k_run.log >/dev/null
if grep -qE "SCRIPT ERROR|ERROR:" /tmp/k_run.log; then
  echo "KIRMIZI: runtime"; grep -E "SCRIPT ERROR|ERROR:" /tmp/k_run.log | head; exit 1; fi
echo "--- 3) mendil smoke ---"
timeout 12 "$G" --headless --path . -- --sobe-round=mendil 2>&1 | tee /tmp/k_m.log >/dev/null
if grep -qE "SCRIPT ERROR|ERROR:" /tmp/k_m.log; then
  echo "KIRMIZI: mendil runtime"; grep -E "SCRIPT ERROR|ERROR:" /tmp/k_m.log | head; exit 1; fi
echo "--- 4) testler ---"
"$G" --headless --path . -- --sobe-encountertest 2>&1 | grep -E '\[SONUC\]' || exit 1
"$G" --headless --path . -- --sobe-briefingtest 2>&1 | grep -E '\[SONUC\]' || exit 1
"$G" --headless --path . -- --sobe-dueltest 2>&1 | grep -E '\[SONUC\]' || exit 1
timeout 400 "$G" --headless --path . -- --sobe-autotest 2>&1 | grep -E "SKOR OK|SKOR HATASI|KILITLENDI" || exit 1
echo "=== HEPSI YESIL ==="
