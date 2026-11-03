#!/usr/bin/env bash
# sample.sh <label> <namespace> [count=6] [interval_s=20] [rawfile]
# Per-workload CPU(m)/MEM(Mi) avg+max from metrics-server (kubectl top), plus total of averages.
# metrics-server reports container working set, not RSS.
set -euo pipefail
label=$1 ns=$2 n=${3:-6} iv=${4:-20} raw=${5:-}
ctx=$(kubectl config current-context); [[ $ctx == kind-* ]] || { echo "refusing: $ctx"; exit 1; }
tmp=$(mktemp)
for _ in $(seq "$n"); do kubectl top pod -n "$ns" --no-headers >> "$tmp"; sleep "$iv"; done
[[ -n $raw ]] && cp "$tmp" "$raw"
echo "## $label ($ns, $n samples x ${iv}s)"
printf "%-36s %8s %8s %8s %8s\n" pod cpu_avg cpu_max mem_avg mem_max
# +0 forces numeric compare: after sub() awk fields are strings and ">" would compare lexically.
awk '{c=$2; m=$3; sub(/m$/,"",c); sub(/Mi$/,"",m); c+=0; m+=0; p=$1; sub(/-[a-z0-9]+-[a-z0-9]+$/,"",p); sub(/-[0-9]+$/,"",p);
  sc[p]+=c; sm[p]+=m; k[p]++; if(c>cm[p])cm[p]=c; if(m>mm[p])mm[p]=m}
  END{for(p in sc){printf "%-36s %8.0f %8.0f %8.0f %8.0f\n",p,sc[p]/k[p],cm[p],sm[p]/k[p],mm[p]; tc+=sc[p]/k[p]; tm+=sm[p]/k[p]}
  printf "~TOTAL(avg)                          %8.0f %8s %8.0f\n",tc,"",tm}' "$tmp" | sort
rm -f "$tmp"
