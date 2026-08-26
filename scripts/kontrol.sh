#!/bin/bash
# YEREL KONTROL = CI + FAZLASI.
# Ders 1: yalniz 'SCRIPT ERROR' aramak yetmez, 'ERROR:' de aranmali.
# Ders 2: SMOKE yetmez. Gercek hatalar TAM MACLARDA cikiyor - kullanicinin
#         debugger'inda gordugumuz "Out of bounds index '4'" hatasi calim
#         hamlesi oynandiginda firliyordu ve 12 saniyelik smoke'ta hic olmadi.
#         Bu yuzden TUM kosumlarin ciktisi hata icin taranir.
S=/tmp/claude-0/-home-user-vaaz-asistani/f43a24d4-86ab-5f62-8ea5-a975c16a92bf/scratchpad
G="$S/Godot_v4.7.2-stable_linux.x86_64"
cd "$S/repo" || exit 1
HATA="SCRIPT ERROR|ERROR:|Out of bounds|Invalid access|Nonexistent"
ara() { if grep -qE "$HATA" "$1"; then echo "KIRMIZI: $2"; grep -E "$HATA" "$1"|head -6; exit 1; fi; }
rm -rf .godot
echo "--- 1) parse ---"
"$G" --headless --editor --quit --path . >/tmp/k1.log 2>&1; ara /tmp/k1.log "parse"
echo "--- 2) smoke ---"
timeout 12 "$G" --headless --path . >/tmp/k2.log 2>&1; ara /tmp/k2.log "yakan top smoke"
timeout 12 "$G" --headless --path . -- --sobe-round=istop >/tmp/k3.log 2>&1; ara /tmp/k3.log "istop smoke"
echo "--- 3) birim testler ---"
for t in encountertest briefingtest dueltest; do
  "$G" --headless --path . -- --sobe-$t >/tmp/kt.log 2>&1; ara /tmp/kt.log "$t"
  grep -E '\[SONUC\]' /tmp/kt.log || { echo "KIRMIZI: $t sonuc vermedi"; exit 1; }
done
echo "--- 4) TAM MACLAR (hata taramasi dahil) ---"
timeout 400 "$G" --headless --path . -- --sobe-autotest >/tmp/k4.log 2>&1
ara /tmp/k4.log "yakan top maci"; grep -E "SKOR OK|SKOR HATASI|KILITLENDI" /tmp/k4.log
for i in 1 2 3; do
  timeout 250 "$G" --headless --path . -- --sobe-autotest --sobe-round=istop >/tmp/k5_$i.log 2>&1
  ara /tmp/k5_$i.log "istop maci $i"; grep -E "SONUC: mac=1|KILITLENDI" /tmp/k5_$i.log|head -1
done
echo "=== HEPSI YESIL ==="
