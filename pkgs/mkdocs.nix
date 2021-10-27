{ pkgs }:

let
  python3Pkgs = pkgs.python3.pkgs;

  mkdocs-gen-files = python3Pkgs.buildPythonPackage rec {
    pname = "mkdocs-gen-files";
    version = "0.3.3";
    src = python3Pkgs.fetchPypi {
      inherit pname version;
      sha256 = "1fwkr0a980psah56whq4g2kmbn9s0scch24q6ij20g9bnvn85zhb";
    };

    buildInputs = [ pkgs.mkdocs ];

    doCheck = false;
  };

  pymdown-extensions = python3Pkgs.buildPythonPackage rec {
    pname = "pymdown-extensions";
    version = "9.0";
    src = python3Pkgs.fetchPypi {
      inherit pname version;
      sha256 = "0h7gk33fb4xmbkliz8g3d7yimw8w82b499w702xflsxiyk3vxr01";
    };

    propagatedBuildInputs = with python3Pkgs; [ markdown ];

    # Note: tests don't pass
    # checkInputs = with python3Pkgs; [ pytest pyyaml ]; 
    doCheck = false;
  };

  mkdocs-material-extensions = python3Pkgs.buildPythonPackage rec {
    pname = "mkdocs-material-extensions";
    version = "1.0.3";
    src = python3Pkgs.fetchPypi {
      inherit pname version;
      sha256 = "18nvznxi5gcs7xhkn5pcd2hnwiw3xgwlh9p4xl9c6hbvxzylvlmz";
    };

    doCheck = false;
  };

  mkdocs-material = python3Pkgs.buildPythonPackage rec {
    pname = "mkdocs-material";
    version = "7.2.3";
    src = python3Pkgs.fetchPypi {
      inherit pname version;
      sha256 = "1pvfjqbcr5cm2nw3knbbi0170k5jym8phs6g378aasimwxi033v8";
    };

    buildInputs = [ pkgs.mkdocs ];

    propagatedBuildInputs = with python3Pkgs; [ 
      pymdown-extensions
      pygments
      mkdocs-material-extensions
    ];
  };

  mkdocs-redirects = python3Pkgs.buildPythonPackage rec {
    pname = "mkdocs-redirects";
    version = "1.0.3";
    src = python3Pkgs.fetchPypi {
      inherit pname version;
      sha256 = "03rlzrcb739abihdfv0znni78pp85bbmk8n04y28vs7m3qfkwhfv";
    };

    buildInputs = [ pkgs.mkdocs ];

    propagatedBuildInputs = with python3Pkgs; [ six ];
  };

  mkdocs-git-revision-date-localized-plugin = python3Pkgs.buildPythonPackage rec {
    pname = "mkdocs-git-revision-date-localized-plugin";
    version = "0.10.0";

    # Don't use pypi because requirements.txt hasn't been uploaded
    src = pkgs.fetchFromGitHub {
      repo = "mkdocs-git-revision-date-localized-plugin";
      owner = "timvink";
      rev = "v${version}";
      sha256 = "0c2ayn5h4wy63qf8v20zh0nycac3vzj9h914f17ihcliw6zy2yry";
    };

    buildInputs = [ pkgs.mkdocs ];

    propagatedBuildInputs = with python3Pkgs; [ GitPython Babel ];
  };


in 

pkgs.mkdocs.overridePythonAttrs (old: rec {
  propagatedBuildInputs = old.propagatedBuildInputs ++ [
    # Add mkdocs plugins
    mkdocs-gen-files
    mkdocs-material
    mkdocs-redirects
    mkdocs-git-revision-date-localized-plugin
  ];
})
