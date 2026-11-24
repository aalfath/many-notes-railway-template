#!/bin/sh
# Bundled Typesense for Many Notes' search, sized for small Railway plans.
# Railway hosts run transparent huge pages "always" and show the host's CPUs,
# so cap jemalloc's huge pages and arenas and the worker threads; otherwise
# Typesense alone holds ~360 MB at 0.5 GB and gets OOM-killed.
export MALLOC_CONF="${TYPESENSE_MALLOC_CONF:-thp:never,metadata_thp:disabled,narenas:2,background_thread:false,dirty_decay_ms:1000,muzzy_decay_ms:0}"
exec /opt/typesense-server --data-dir=/data/typesense --api-key="$TYPESENSE_API_KEY" \
  --api-address=127.0.0.1 --api-port=8108 --peering-address=127.0.0.1 \
  --thread-pool-size="${TYPESENSE_THREADS:-2}" --max-indexing-concurrency="${TYPESENSE_THREADS:-2}" \
  --num-collections-parallel-load=1 --num-documents-parallel-load=200 \
  --cache-num-entries=100 --enable-cors=false "$@"
