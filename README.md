# SONAR Example

Following along with the [paper] and [vignette] for
[SONAR].

A very rough setup script to automate a few things.  Creates a sonar conda
environment.

    bash setup.sh

And then:

    conda activate sonar
    export PATH="$(readlink -f SONAR):$PATH"

[paper]: https://doi.org/10.3389/fimmu.2016.00372
[vignette]: https://github.com/scharch/SONAR/blob/master/vignette.pdf
[SONAR]: https://github.com/scharch/SONAR
