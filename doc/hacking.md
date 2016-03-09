In general we believe it is a good idea to record principles for
posterity. These rules are numbered statically to allow referencing them.

 1.   Boiler plate from upstream should be removed when copying config.
      files into a role.

 2.   Static configs, or templates that create config files, should only
      contain options that are different from the service default.

 3.   Comments in templates should only reach the final-product config file
      if they are aimed at helping operators understand the config options.
      Developer centric comments should be wrapped and comented in the
      template language so they do not reach the final config file.
