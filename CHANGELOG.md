### 0.1.4 / 2017-09-10

* Use `9` instead of `8` as the `windowBits` parameter to zlib, to deal with
  restrictions introduced in zlib v1.2.9

### 0.1.3 / 2016-05-20

* Amend all warnings issued when running with -W2

### 0.1.2 / 2015-11-06

* The server does not send `server_max_window_bits` if the client does not ask
  for it; this works around an issue in Firefox.

### 0.1.1 / 2014-12-18

* Don't allow configure() to be called with unrecognized options

### 0.1.0 / 2014-12-13

* Initial release
