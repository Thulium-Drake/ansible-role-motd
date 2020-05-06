local Converge(distro) = {
  name: "Converge - "+distro,
  image: "registry.element-networks.nl/tools/molecule",
  commands: [
    "molecule destroy",
    "molecule converge",
    "molecule destroy",
  ],
  environment:
    { MOLECULE_DISTRO: +distro, },
  privileged: true,
  volumes: [
    { name: "docker", path: "/var/run/docker.sock" },
  ],
};

[
  {
    name: "Lint",
    kind: "pipeline",
    steps: [
      {
        name: "Lint code",
        image: "registry.element-networks.nl/tools/molecule",
        commands: [
          "molecule lint",
          "molecule syntax"
        ]
      }
    ]
  },
#  {
#    kind: "pipeline",
#    name: "Test",
#    steps: [
#      Converge("debian10"),
#      Converge("ubuntu2004"),
#      Converge("centos7"),
#    ],
#    volumes: [
#      { name: "docker",
#        host: { path: "/var/run/docker.sock" }
#      },
#    ],
#    depends_on: [
#      "Lint",
#    ],
#  },
  {
    name: "Publish",
    kind: "pipeline",
    clone:
      { disable: true },
    steps: [
      {
        name: "Ansible Galaxy",
        image: "registry.element-networks.nl/tools/molecule",
        commands: [
          "ansible-galaxy login --github-token $$GITHUB_TOKEN",
          "ansible-galaxy import Thulium-Drake ansible-role-motd --role-name=motd",
        ],
        environment:
          { GITHUB_TOKEN: { from_secret: "github_token" } },
      },
    ],
    depends_on: [
      "Lint",
    ],
  },
]
