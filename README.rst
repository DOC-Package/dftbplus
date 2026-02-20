*****************************************************************
DFTB+: general package for performing fast atomistic calculations
*****************************************************************

|lgpl badge|

DFTB+ is a software package for carrying out fast quantum mechanical atomistic
calculations based on the Density Functional Tight Binding method. The most
recent features are described in the (open access) `DFTB+ paper
<https://doi.org/10.1063/1.5143190>`_.

|DFTB+ logo|

DFTB+ can be either used as a standalone program or integrated into other
software packages as a library.


About this fork
===============

This repository is a fork of DFTB+ modified for Constrained DFT (CDFT)
development and CDFTB-CI calculations. The following modifications have been made:

**Spin constraint implementation (NEW):**

The original DFTB+ electronic constraints only supported charge (population)
constraints. This fork adds support for **spin (magnetization) constraints**,
enabling control of local magnetic moments in spin-polarized calculations.

*Theory:*

In spin-polarized calculations, Mulliken populations are stored in the [q, m]
representation:

- q = (n_α + n_β) / 2  (charge)
- m = (n_α - n_β) / 2  (magnetization)

The constraint is applied via ``spinChannelFactors`` which weight the [q, m]
components:

+-------------------+------------------------+----------------------+
| Constraint Type   | spinChannelFactors     | Constrained Quantity |
+===================+========================+======================+
| Charge (default)  | [1.0, 0.0]             | q                    |
+-------------------+------------------------+----------------------+
| Magnetization     | [0.0, 1.0]             | m                    |
+-------------------+------------------------+----------------------+
| Alpha only        | [1.0, 1.0]             | q + m = n_α          |
+-------------------+------------------------+----------------------+
| Beta only         | [1.0, -1.0]            | q - m = n_β          |
+-------------------+------------------------+----------------------+

*New input keywords:*

- ``TotalSpin``: Constrain total spin magnetization over specified atoms
- ``Spins``: Constrain individual atom spin magnetizations

*Usage example (charge constraint only):*

::

    ElectronicConstraints {
      Constraints {
        MullikenPopulation {
          Atoms = 1:36
          TotalCharge = 1.0
        }
      }
    }

*Usage example (spin constraint only):*

::

    ElectronicConstraints {
      Constraints {
        MullikenPopulation {
          Atoms = 1:36
          TotalSpin = 1.0
        }
      }
    }

*Usage example (simultaneous charge and spin constraints):*

::

    ElectronicConstraints {
      Constraints {
        MullikenPopulation {
          Atoms = 1:36
          TotalCharge = 1.0
        }
        MullikenPopulation {
          Atoms = 1:36
          TotalSpin = 2.0
        }
      }
      Optimiser {
        FIRE {}
      }
      ConstrTolerance = 1e-4
      MaxConstrIterations = 200
      ConvergentConstrOnly = Yes
    }

*Implementation details:*

- Added spin channel type constants (``spinChannelCharge``, ``spinChannelMagnetization``,
  ``spinChannelAlpha``, ``spinChannelBeta``) in ``elecconstraints.F90``
- Modified ``readMullikenConstraintInputs`` to parse ``TotalSpin`` and ``Spins`` keywords
- ``spinChannelFactors`` are automatically set based on the constraint type
- Validation ensures spin constraints are only used in spin-polarized calculations
- Multiple constraints (charge + spin) can be applied simultaneously with
  independent constraint potentials (Vc)

**Enhanced output for electronic constraints:**

- Added ``Vc`` (constraint potential) output to SCC iteration information
  (``printSccInfo`` in ``mainio.F90``)
- Added ``Vc`` output to constraint iteration information
  (``printElecConstrInfo`` in ``mainio.F90``)
- Added automatic export of final constraint potential to ``final_Vc.dat`` file
  after convergence (``writeFinalVc`` in ``main.F90``)
- Added getter functions (``getVc``, ``getDeviation``, ``getNConstr``) to
  ``TElecConstraint`` type for accessing constraint data (``elecconstraints.F90``)
- **Multiple Vc output**: When multiple constraints are present (e.g., charge + spin),
  all Vc values are displayed as ``Vc(1)``, ``Vc(2)``, etc.

These modifications are useful for:

- Controlling local spin states in magnetic systems
- Studying spin-dependent charge transfer processes
- Monitoring constraint convergence during SCC iterations
- Extracting final constraint potentials for CDFTB-CI coupling calculations
- Debugging and analysis of constrained DFT calculations

**Modified files:**

- ``src/dftbp/dftb/elecconstraints.F90``
- ``src/dftbp/dftbplus/main.F90``
- ``src/dftbp/dftbplus/mainio.F90``


**External point charge energy output:**

Added separate output for the electrostatic interaction energy between DFTB
atoms and external point charges in ``detailed.out``.

*Background:*

When using ``PointCharges`` in QM/MM calculations, the interaction energy
with external charges was included in the SCC energy (``energy%Escc``) but
not displayed separately. This makes it difficult to analyze the QM/MM
coupling energy.

*Implementation:*

- Added ``EPointCharge`` and ``atomPointCharge(:)`` to ``TEnergies`` type
  for storing point charge interaction energy
- Added ``getPointChargeEnergyPerAtom`` method to ``TScc`` type to extract
  the point charge energy contribution separately
- Modified ``calcEnergies`` in ``getenergies.F90`` to calculate and store
  the point charge energy
- Added output line ``Energy point charges`` to ``detailed.out`` when
  point charges are present (independent of ``isExtField`` flag)

*Output example:*

In ``detailed.out``, a new line appears when external point charges are used::

    Energy point charges       -0.0234567890 H       -0.6384728193 eV

*Modified files:*

- ``src/dftbp/dftb/energytypes.F90``
- ``src/dftbp/dftb/scc.F90``
- ``src/dftbp/dftb/getenergies.F90``
- ``src/dftbp/dftbplus/mainio.F90``


Installation
============

Obtaining via Conda
-------------------

The preferred way of to install DFTB+ is by using the conda package management
system. We highly suggest using the `miniforge
<https://github.com/conda-forge/miniforge>`_ conda distribution. You might use
any other conda distribution as well, just make sure to select the `conda-forge
<https://conda-forge.org/>`_ channel as the (only) source for packages.

We provide several build variants, choose the one suiting your needs. For
example, by issuing ::

  conda install 'dftbplus=*=nompi_*'

or ::

  conda install 'dftbplus=*=mpi_mpich_*'

or ::

  conda install 'dftbplus=*=mpi_openmpi_*'

to get the last stable release of DFTB+ with, respectively, serial
(OpenMP-threaded) build or with MPI-parallelized build using either the MPICH or
the Open MPI framework.


Downloading the binary
----------------------

A non-MPI (OpenMP-threaded) distribution of the latest stable release can be
found on the `stable release page
<http://www.dftbplus.org/download/stable.html>`_.


Building from source
--------------------

**Note:** This section describes the building with default settings (offering
only a subset of all possible features in DFTB+) in a typical Linux
environment. For more detailed information on the build customization and the
build process, consult the **detailed building instructions** in `INSTALL.rst
<INSTALL.rst>`_.

Download the source code from the `stable release page
<http://www.dftbplus.org/download/stable.html>`_.

You need CMake (>= 3.16) to build DFTB+. If your environment offers no CMake or
only an older one, you can easily install the latest CMake via Python's ``pip``
command::

  pip install cmake

Start CMake by passing your compilers as environment variables (``FC`` and
``CC``), and the location where the code should be installed and the build
directory (``_build``) as options::

  FC=gfortran CC=gcc cmake -DCMAKE_INSTALL_PREFIX=$HOME/opt/dftb+ -B _build .

If the configuration was successful, start the build with::

  cmake --build _build -- -j

After successful build, you should test the code. First download the files
needed for the test ::

  ./utils/get_opt_externals slakos
  ./utils/get_opt_externals gbsa

or ::

  ./utils/get_opt_externals ALL

and then run the tests with ::

  pushd _build; ctest -j; popd

If the tests were successful, install the package with ::

  cmake --install _build

For further details see the `detailed building instructions <INSTALL.rst>`_.


Parameterisations
=================

In order to carry out calculations with DFTB+, you need according
parameterisations (a.k.a. Slater-Koster files). You can download them from
`dftb.org <https://dftb.org>`_.


Documentation
=============

Consult following resources for documentation:

* `Step-by-step instructions with selected examples (DFTB+ Recipes)
  <http://dftbplus-recipes.readthedocs.io/>`_

* `Reference manual describing all features (DFTB+ Manual)
  <https://github.com/dftbplus/dftbplus/releases/latest/download/manual.pdf>`_


Citing
======

When publishing results obtained with DFTB+, please cite following works:

* `DFTB+, a software package for efficient approximate density functional theory
  based atomistic simulations; J. Chem. Phys. 152, 124101 (2020)
  <https://doi.org/10.1063/1.5143190>`_

* Reference publications of the Slater-Koster parameterization sets you
  used. (See `dftb.org <https://dftb.org>`_ for the references.)

* Methodological papers relevant to your calculations (e.g. excited states,
  electron-transport, third order DFTB etc.). References to these can be found
  in the `DFTB+ manual
  <https://github.com/dftbplus/dftbplus/releases/latest/download/manual.pdf>`_.


Contributing
============

New features, bug fixes, documentation, tutorial examples and code testing is
welcome in the DFTB+ developer community!

The project is `hosted on github <http://github.com/dftbplus/>`_.
Please check `CONTRIBUTING.rst <CONTRIBUTING.rst>`_ and the `DFTB+ developers
guide <https://dftbplus-develguide.readthedocs.io/>`_ for guide lines.

We are looking forward to your pull request!


License
=======

DFTB+ is released under the GNU Lesser General Public License. See the included
`LICENSE <LICENSE>`_ file for the detailed licensing conditions.



.. |DFTB+ logo| image:: https://www.dftbplus.org/_assets/DFTB-Plus-Icon_06_f_150x150.png
    :alt: DFTB+ website
    :scale: 100%
    :target: https://dftbplus.org/

.. |lgpl badge| image:: http://www.dftbplus.org/_assets/license-GNU-LGPLv3-blue.svg
    :alt: LGPL v3.0
    :scale: 100%
    :target: https://opensource.org/licenses/LGPL-3.0
