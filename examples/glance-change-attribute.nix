/*
Most containers come with preconfigured Glance coniguration.
They will set category, name, description, href, ...
You can override these values if desired.

The options are not available on stack level, so we can refer to the container options
*/
{lib, ...}: {
  nps.stacks = {
    adguard.containers.adguard.glance = {
      category = lib.mkForce "New Category";
      name = lib.mkForce "New Name";
      description = lib.mkForce "New Description";
      icon = lib.mkForce "di:new-icon";
    };
  };
}
