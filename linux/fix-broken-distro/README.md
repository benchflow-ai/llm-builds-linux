# Fix Broken Linux Distribution Build

## Overview

This experiment tests whether an LLM agent can debug and fix a broken Linux distribution build configuration. The task requires identifying 16 deliberate configuration errors, understanding their root causes, and systematically fixing them while maintaining system coherence.

## Why This Matters

Building Linux distributions requires deep system knowledge and careful attention to multi-component dependencies. This experiment tests abilities that are crucial for:

- **AI Hardware Companies**: Building custom Linux images for embedded systems
- **DevOps/SRE**: Debugging system configuration issues
- **System Administrators**: Understanding Linux internals
- **Coding Agents**: Long-horizon debugging with complex feedback loops

Unlike simple code bugs, these issues span multiple files, have interconnected dependencies, and some only manifest at boot time rather than build time.

## The Challenge

### What's Broken

The build configuration contains 16 errors across 4 files:

1. **debootstrap.conf** - Bootstrap configuration
   - Invalid architecture specification
   - Missing kernel package

2. **fstab** - Filesystem mount table
   - Wrong filesystem type
   - Missing critical mount points
   - Invalid swap device

3. **grub-config.sh** - Bootloader installation
   - Command typo
   - Wrong device
   - Missing config generation
   - Missing boot parameters

4. **setup-chroot.sh** - System configuration
   - Wrong package names
   - Interactive commands
   - Missing locale/timezone/DNS config
   - Invalid network interface

### Difficulty Breakdown

- **Critical (8)**: Block build or boot completely
- **High (4)**: System boots but severely degraded
- **Medium (2)**: Minor functionality issues
- **Low (2)**: Cosmetic or optional

## Getting Started

### Prerequisites

- Docker (for isolated build environment)
- Basic understanding of Linux system administration
- Familiarity with debootstrap and package management

### Project Structure

```
fix-broken-distro/
├── README.md                    # This file
├── BROKEN.md                    # Detailed list of all issues
├── EXPERIMENT.yaml              # Experiment metadata
├── Dockerfile                   # Build environment
├── debootstrap.conf             # BROKEN: Bootstrap config
├── fstab                        # BROKEN: Filesystem table
├── grub-config.sh               # BROKEN: Bootloader setup
├── setup-chroot.sh              # BROKEN: System config
├── debootstrap.conf.fixed       # Fixed version
├── fstab.fixed                  # Fixed version
├── grub-config.sh.fixed         # Fixed version
├── setup-chroot.sh.fixed        # Fixed version
├── test-build.sh                # Validation script
├── build.sh                     # Build with broken config
├── build-fixed.sh               # Build with fixed config
└── trajectories/
    └── SUMMARY.md               # Debugging process documentation
```

## Running the Experiment

### Step 1: Static Analysis

Read and analyze the configuration files:

```bash
# Review broken configurations
cat debootstrap.conf
cat fstab
cat grub-config.sh
cat setup-chroot.sh
```

### Step 2: Run Validation Tests

Use the automated test suite:

```bash
chmod +x test-build.sh
./test-build.sh
```

This will identify many (but not all) issues through static checks.

### Step 3: Attempt Build

Try building with the broken configuration:

```bash
# Build Docker image
docker build -t fix-distro .

# Run broken build (will fail)
docker run --privileged -it fix-distro ./build.sh
```

**Note**: The build will fail at various stages. Document each failure!

### Step 4: Fix Issues Iteratively

For each error:
1. Identify the root cause
2. Understand the impact
3. Make the fix
4. Test that fix doesn't break other things
5. Document your reasoning

### Step 5: Validate Fixed Configuration

```bash
# Test with fixed configuration
docker run --privileged -it fix-distro ./build-fixed.sh
```

### Step 6: Compare and Learn

```bash
# Compare broken vs fixed
diff debootstrap.conf debootstrap.conf.fixed
diff fstab fstab.fixed
diff grub-config.sh grub-config.sh.fixed
diff setup-chroot.sh setup-chroot.sh.fixed
```

## Key Learning Points

### 1. Architecture Matters
Invalid architecture (`i368` instead of `amd64`) causes immediate failure.

### 2. Build vs. Runtime Errors
Some issues (like missing kernel) allow build to succeed but system won't boot.

### 3. Multi-File Dependencies
Fixes in one file may require changes in others (e.g., fstab and GRUB config).

### 4. Distribution Differences
Package names vary: `linux-image-amd64` (Debian) vs `linux-image-generic` (Ubuntu).

### 5. Interactive vs. Automated
Commands like `passwd` must be replaced with `chpasswd` for automated builds.

### 6. Boot Process Understanding
Must understand: bootloader → kernel → init system → user space.

## Expected Debugging Flow

1. **Static Analysis** (15 min)
   - Read all configuration files
   - Identify obvious typos and errors

2. **Test Framework** (20 min)
   - Create automated validation
   - Check common issues

3. **Issue Identification** (25 min)
   - Categorize by severity
   - Understand dependencies

4. **Iterative Fixing** (40 min)
   - Fix critical blockers first
   - Test after each fix
   - Ensure no regressions

5. **Validation** (15 min)
   - Run complete build
   - Verify all components work

6. **Documentation** (20 min)
   - Record debugging process
   - Note lessons learned

**Total Time**: 2-3 hours for thorough completion

## Success Criteria

### Minimum (Pass)
- [ ] Identify at least 12/16 issues
- [ ] Fix all critical (build-blocking) issues
- [ ] Debootstrap completes successfully
- [ ] Document debugging process

### Good (Strong Pass)
- [ ] Identify all 16 issues
- [ ] Fix all issues correctly
- [ ] No regressions introduced
- [ ] Clear documentation of reasoning

### Excellent (Outstanding)
- [ ] All issues fixed with explanations
- [ ] System boots in QEMU
- [ ] Additional security hardening
- [ ] Automated test suite created
- [ ] Comparison with best practices

## Common Pitfalls

### 1. Fixing Symptoms Not Causes
Don't just make errors disappear - understand why they're errors.

### 2. Breaking Working Configs
Some parts of the broken config are actually correct. Don't change them!

### 3. Incomplete Fixes
Fixing a typo but not the underlying logic issue.

### 4. Missing Dependencies
Fixing one issue but not related configurations.

### 5. Testing Too Late
Test after each fix, not all at once.

## Advanced Extensions

Once you've completed the basic task:

1. **Boot Test**: Use QEMU to verify the system actually boots
   ```bash
   qemu-system-x86_64 -drive file=disk.img,format=raw -m 1G
   ```

2. **Security Audit**: Identify security misconfigurations
   - Default passwords
   - Missing firewall rules
   - Unnecessary services

3. **Performance Analysis**: Find performance bottlenecks
   - Slow package selections
   - Inefficient mount options
   - Missing optimizations

4. **Multi-Distribution**: Port fixes to Ubuntu/Fedora
   - Understand distribution differences
   - Package name variations
   - Different init systems

5. **Automated Recovery**: Create self-healing scripts
   - Detect common issues
   - Auto-fix when possible
   - Report complex problems

## Resources

### Documentation
- [Debootstrap Manual](https://wiki.debian.org/Debootstrap)
- [Debian Installation Guide](https://www.debian.org/releases/stable/amd64/)
- [GRUB Manual](https://www.gnu.org/software/grub/manual/)
- [Linux Filesystem Hierarchy](https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf)

### Related Experiments
- Build minimal Linux from scratch (LFS)
- Create custom Ubuntu live ISO
- Configure Yocto/Buildroot for embedded
- Container-optimized distro (Alpine-style)

## Evaluation Metrics

This experiment tracks:
- **Issues found**: X/16
- **Critical fixes**: X/8
- **Time to complete**: X hours
- **Build success**: Yes/No
- **Boot success**: Yes/No (if QEMU tested)
- **Documentation quality**: Detailed/Good/Basic

## Contributing

Found additional interesting bugs to add? Want to create variants?

1. Document the new issue in BROKEN.md
2. Update EXPERIMENT.yaml with new metrics
3. Add to test-build.sh validation
4. Update this README

## License

This experiment is part of the llm-builds-linux benchmark suite.

## Questions?

See `BROKEN.md` for detailed issue descriptions and `trajectories/SUMMARY.md` for example debugging process.
