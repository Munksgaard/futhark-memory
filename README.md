# futhark-memory

## How to save results of benchmark run

```
make -C benchmarks
cp -R benchmarks results/MACHINE
find results -type f -not -name '*.json' -delete
```

## Syncing datasets with erda

After having set up an `erda` and `hpa01` remote in rclone:

```
[erda]
type = sftp
host = io.erda.dk
user = pmunk@di.ku.dk
md5sum_command = none
sha1sum_command = none

[hpa01]
type = sftp
host = futharkhpa01fl.unicph.domain
user = jxk588
pass = SET IN `rclone config`
md5sum_command = md5sum
sha1sum_command = sha1sum
```

```
rclone -P --include "benchmarks/**.data" sync hpa01:src/futhark-memory erda:futhark-memory/
```

## Uploading files to erda

```bash
for size in 2048 4096 8192 16384 32768
do
  ~/src/futhark-benchmarks/add-data.sh https://sid.erda.dk/share_redirect/CpaxUK05eK/benchmarks/hotspot/data/power_$size.data
  ~/src/futhark-benchmarks/add-data.sh https://sid.erda.dk/share_redirect/CpaxUK05eK/benchmarks/hotspot/data/temp_$size.data
done
```
