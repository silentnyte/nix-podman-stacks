{
  config,
  lib,
  ...
}: let
  forwardAuthContainers =
    lib.filterAttrs (k: c: c.forwardAuth.enable && c.forwardAuth.rules != [])
    config.services.podman.containers;
  forwardAuthCfg = lib.mapAttrs (name: c: c.forwardAuth) forwardAuthContainers |> lib.attrValues;
in {
  config = lib.mkIf (forwardAuthContainers != {}) {
    nps.stacks.authelia.settings.access_control.rules = lib.mkMerge (forwardAuthCfg |> map (e: lib.mkOrder e.rulesOrder e.rules));
  };

  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      config = lib.mkIf config.forwardAuth.enable {
        traefik.middleware.authelia = {
          enable = true;
          order = config.forwardAuth.middlewareOrder;
        };
        wantsContainer = ["authelia"];
      };
      options.forwardAuth = with lib; {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable forward auth. This will enable the `authelia` Traefik middleware for this container.
            Every request will be forwarded to be authorized by Authelia first.

            Optionally, access control rules for this container can be specified in the settings.
            They will be added to the Authelia settings.

            See <https://www.authelia.com/configuration/security/access-control/>
          '';
        };
        middlewareOrder = lib.mkOption {
          type = lib.types.int;
          default = 1000;
          description = ''
            Order of the `authelia` middleware. Multiple middlewares will be called in order by Traefik, with lower orders
            being called first.
          '';
        };
        rulesOrder = lib.mkOption {
          type = lib.types.int;
          default = 1000;
          description = ''
            Order of rules when merged into the authelia settings.
            The order will be applied using `lib.mkOrder <order>` when applying the rules in the Authelia settings.
            Lower numbers mean the rules will appear earlier in the `access_control.rules` list, which give them a higher priority.

            See <https://www.authelia.com/configuration/security/access-control/#rule-matching-concept-1-sequential-order>
          '';
        };
        rules = mkOption {
          type = with types;
            listOf (submodule {
              options = {
                domain = mkOption {
                  type = listOf str;
                  default = [config.traefik.serviceHost];
                  defaultText = lib.literalExpression ''[ containerCfg.traefik.serviceHost ]'';
                  description = ''
                    Domain(s) that will be matched for the rule. Defaults to the servie domain registered in Traefik.
                    Either this, or the `domain_regex` options has to be set.

                    See <https://www.authelia.com/configuration/security/access-control/#domain>
                  '';
                };
                domain_regex = mkOption {
                  type = listOf str;
                  default = [];
                  description = ''
                    Regex(es) criteria matching the domain. Defaults to the servie domain registered in Traefik.
                    Has to be set if the domain is unset.

                    See <https://www.authelia.com/configuration/security/access-control/#domain_regex>
                  '';
                };
                policy = mkOption {
                  type = enum ["" "deny" "bypass" "one_factor" "two_factor"];
                  default = "";
                  description = ''
                    The specific policy to apply to the selected rule.
                    This is not criteria for a match, this is the action to take when a match is made.

                    See <https://www.authelia.com/configuration/security/access-control/#policy>
                  '';
                };
                subject = mkOption {
                  type = listOf (either str (listOf str));
                  default = [];
                  description = ''
                    Criteria that matches the subject.

                    See <https://www.authelia.com/configuration/security/access-control/#subject>
                  '';
                };
                methods = mkOption {
                  type = listOf str;
                  default = [];
                  description = ''
                    Critera matching the HTTP request method.

                    See <https://www.authelia.com/configuration/security/access-control/#methods>
                  '';
                };
                networks = mkOption {
                  type = listOf str;
                  default = [];
                  description = ''
                    Critera matching the network. Can be a list of IP addresses, CIDR ranges or named network definitions.

                    See <https://www.authelia.com/configuration/security/access-control/#networks>
                  '';
                };
                resources = mkOption {
                  type = listOf str;
                  default = [];
                  description = ''
                    Critera matching the path and query parameter using regular expressions.

                    See <https://www.authelia.com/configuration/security/access-control/#resources>
                  '';
                };
              };
            });
          default = [];
          description = ''
            Rules matching a request. When all criteria of a rule match the request, the defined `policy` is applied.

            See <https://www.authelia.com/configuration/security/access-control/#rules>
          '';
        };
      };
    }));
  };
}
