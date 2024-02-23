---
title: Configure Nebula VPN on iOS/Android
---

Nebula is now available on iOS and Android, which is very exciting. What is less exciting is the fact I couldn't find any documentation on how to set it up. You're in luck though, because that's just what I've got here - how to setup Nebula on a server, and connect that to a mobile device.

# Setup Nebula on a server

Installing Nebula is a fairly straightforward (but manual) process. It's not available in any PPAs (that I know of), so it's a bit involved.

On the server that will be your lighthouse (ie a server that has a public static IP, and can open a port to the outside world).

1. Download the latest release for your platform from [GitHub](https://github.com/slackhq/nebula/releases).
1. Extract the archive and put `nebula` and `nebula-cert` somewhere in your `$PATH` - like `/usr/local/bin`. Make sure they're executable: `sudo chmod +x /usr/local/bin/nebula*`.
1. Download the [example config](https://github.com/slackhq/nebula/blob/master/examples/config.yml) to `/etc/nebula/config.yml`.

Now let's generate some certificates! Generate a CA cert:

```shell
$ nebula-cert ca -name "My Mesh Network"
```

You should now have `ca.key` and `ca.crt`. Keep `ca.key` super secret - anyone that has access to that has the ability to add new nodes to your network!

Generate a cert for the lighthouse node:

```shell
$ nebula-cert sign -name "lighthouse" -ip "10.45.54.1/24"
```

> The IP address can be anything in the range of [private network address space](https://en.wikipedia.org/wiki/Private_network). Easiest thing to do is just `10.X.Y.Z` - but choose IPs that aren't already common on private networks! Many routers give out `10.1.1.X`, and so your VPN could clash with devices on your network.

You should now also have `lighthouse.crt` and `lighthouse.key`. You can repeat the `nebula-cert sign` command for each node in the network - giving them each their own IP.

Now update the `config.yml` with the VPN IP and external IP/port of your lighthouse. Find the section like this:

```yaml
static_host_map:
  # "<Nebula VPN IP>": ["<external IP or addresss>:<port>"]
  # eg:
  "10.45.54.1": ["185.199.108.153:4242"]
```

This allows new nodes to make their initial connection. The external address can be a URL (I actually use a dynamic DNS provider to point to my home computer). The port must be open to the outside world, and listed in the `listen` section:

```yaml
listen:
  host: 0.0.0.0
  port: 4242
```

For lighthouses, you need to set `am_lighthouse: true`. For all other nodes you need to set `lighthouse.hosts` to a list of the Nebula IPs of the lighthouses. See the [example config file](https://github.com/slackhq/nebula/blob/master/examples/config.yml) for more info, and all the other options you can set.

You can now start nebula:

```shell
$ nebula -config /etc/nebula/config.yml
```

If you want to run it in the background and have it run at boot - look at the [service scripts](https://github.com/slackhq/nebula/blob/master/examples/service_scripts/nebula.service).

# Setup on iOS/Android

Get the app ([iOS](https://apps.apple.com/us/app/mobile-nebula/id1509587936?itsct=apps_box&itscg=30200)/[Android](https://play.google.com/store/apps/details?id=net.defined.mobile_nebula)). Click "+" to add a new config, and copy the public key for the device (from the "Certificate" screen) onto your machine that has `ca.key` on it.

Sign the key using `ca.key`:

```shell
$ nebula-cert sign -ca-crt ./ca.crt \
  -ca-key ./ca.key -in-pub <mobile key file> \
  -name <device name> -ip 10.45.54.2/24
```

This should produce `<device name>.crt`. Copy that and `ca.crt` back to your phone.

Paste the contents of `<device name>.crt` onto the "certificate" screen, and the contents of `ca.crt` onto the "CA" screen. Click "Load certificate"/"Load CA" after pasting each cert.

In the "hosts" screen, set the IP of your lighthouse, as well as its public IP and port. Flip the "lighthouse" toggle on.

Once you've entered that, you can save the config. This should prompt a system dialog to enter your passcode to add the new VPN config. You can then use the Nebula app or VPN settings screen to enable Nebula. It will take a second to connect, then you should be able to access all the devices on your VPN.

Simple!
