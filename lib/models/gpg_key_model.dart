class GPGKey {
  final String privateKey;
  final String publicKey;
  final String passphrase;

  GPGKey({required this.privateKey, required this.publicKey, required this.passphrase});
}