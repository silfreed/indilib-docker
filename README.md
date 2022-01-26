# indilib-docker

# example execution

```
docker run --init -it \
  -p 7624:7624 \
  --privileged -v /dev/bus/usb:/dev/bus/usb \
  silfreed/indilib:latest \
  -vv indi_celestron_gps indi_asi_ccd
```

