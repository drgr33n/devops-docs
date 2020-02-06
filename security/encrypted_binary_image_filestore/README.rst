=============================================
How to create an encrypted binary image store
=============================================

:Author:
    Zarren Spry <zarrenspry@gmail.com>
:Version: 0.0.1
:Date: 6th February 2020

These are handy when you need some quick storage for sensitive files. They use strong encryption and
can be distributed relatively safely. I like to use LUKS2 with argon2id as the key derivation function.

First, we will need to create a raw binary image to hold the filesystem.

.. code-block:: bash

    dd if=/dev/random of=${IMAGE_NAME} bs=1 count=0 seek=${SIZE}

Next, let's create a partition within the image.

.. code-block:: bash

    # Create a GPT table
    parted ./$(IMAGE_NAME) mklabel gpt
    # Fill image with one partition
    parted ./$(IMAGE_NAME) mkpart primary 0% 100%

Now lets create the LUKS container within the image.

.. code-block:: bash

    cryptsetup luksFormat -M luks2 --pbkdf argon2id -i 5000 ./$(IMAGE_NAME)

We can verify that the LUKS container was created and with the correct format by using the
luksDump option.

.. code-block:: bash

    cryptsetup luksDump ./$(IMAGE_NAME)

The output should look like the following

.. code-block::

    LUKS header information
    Version:        2
    Epoch:          3
    Metadata area:  16384 [bytes]
    Keyslots area:  16744448 [bytes]
    UUID:           c5775da5-96f7-4c91-96a2-9fa52d8401cf
    Label:          (no label)
    Subsystem:      (no subsystem)
    Flags:          (no flags)

    Data segments:
      0: crypt
            offset: 16777216 [bytes]
            length: (whole device)
            cipher: aes-xts-plain64
            sector: 512 [bytes]

    Keyslots:
      0: luks2
            Key:        512 bits
            Priority:   normal
            Cipher:     aes-xts-plain64
            Cipher key: 512 bits
            PBKDF:      argon2id
            Time cost:  17
            Memory:     1048576
            Threads:    4
            Salt:       e9 bb 69 5b 4b 29 8a b5 1b 95 91 9c ac d7 11 2e
                        24 95 6d 1b 65 f6 6d f6 42 6a cb 85 a1 3f f6 76
            AF stripes: 4000
            AF hash:    sha256
            Area offset:32768 [bytes]
            Area length:258048 [bytes]
            Digest ID:  0
    Tokens:
    Digests:
      0: pbkdf2
            Hash:       sha256
            Iterations: 118509
            Salt:       b4 29 ae 41 ea fb 78 4d 89 ed 0c b7 2a 14 60 88
                        0e c0 ad 5b fb 22 39 89 5b 56 f5 a2 53 d8 89 f2
            Digest:     0a 06 52 42 6d 74 8c 6c 87 7f fa da b3 e3 f1 71
                        b2 b9 2c 1f 02 1c b6 18 9b 6a 85 13 a4 a2 ec 00

Next, we will need to mount the LUKS image and format with a filesystem. M_NAME is the desired
device node name that will be created within **/dev/mapper**.

.. code-block:: bash

    cryptsetup luksOpen ./$(IMAGE_NAME) ${M_NAME}

This command will prompt for the password you used when creating the container. Once you have
successfully unlocked the container, you can check the status with the following command.

.. code-block:: bash

    cryptsetup status ${M_NAME}

Here is my output from the command above

.. code-block:: bash

    /dev/mapper/enc_dev1 is active.
      type:    LUKS2
      cipher:  aes-xts-plain64
      keysize: 512 bits
      key location: keyring
      device:  /dev/loop0
      loop:    /home/drgr33n/Projects/devops-docs/test.img
      sector size:  512
      offset:  32768 sectors
      size:    2064384 sectors
      mode:    read/write

Now we can create the filesystem.

.. code-block:: bash

    mkfs.ext4 /dev/mapper/${M_NAME}

And your image is ready to mount. You can close the container with the following command

.. code-block:: bash

    cryptsetup luksClose /dev/mapper/${M_NAME}

I've included a script to create an encrypted binary image for convenience.