# Encrypting a File Using Symmetric Encryption 

- $  gpg --symmetric --cipher-algo AES256 original_file.txt

- $  gpg --decrypt --output decrypted_file.txt original_file.txt.gpg
