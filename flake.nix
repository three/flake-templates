{
  description = "Useful flake templates";

  outputs = { self }: {
    templates.latex.path = ./latex;
    templates.python.path = ./python;
  };
}
