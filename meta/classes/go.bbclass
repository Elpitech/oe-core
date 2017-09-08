inherit goarch

def get_go_parallel_make(d):
    pm = (d.getVar('PARALLEL_MAKE') or '').split()
    # look for '-j' and throw other options (e.g. '-l') away
    # because they might have a different meaning in golang
    while pm:
        opt = pm.pop(0)
        if opt == '-j':
            v = pm.pop(0)
        elif opt.startswith('-j'):
            v = opt[2:].strip()
        else:
            continue

        return '-p %d' % int(v)

    return ""

GO_PARALLEL_BUILD ?= "${@get_go_parallel_make(d)}"

GOROOT_class-native = "${STAGING_LIBDIR_NATIVE}/go"
GOROOT = "${STAGING_LIBDIR_NATIVE}/${TARGET_SYS}/go"
GOBIN_FINAL_class-native = "${GOROOT_FINAL}/bin"
GOBIN_FINAL = "${GOROOT_FINAL}/${GO_BUILD_BINDIR}"

DEPENDS_GOLANG_class-target = "go-cross-${TARGET_ARCH}"
DEPENDS_GOLANG_class-native = "go-native"

DEPENDS_append = " ${DEPENDS_GOLANG}"

export GOBUILDFLAGS ?= "-v"
GOBUILDFLAGS_prepend_task-compile = "${GO_PARALLEL_BUILD} "

export GOOS = "${TARGET_GOOS}"
export GOARCH = "${TARGET_GOARCH}"
export GOARM = "${TARGET_GOARM}"
export CGO_ENABLED = "1"
export GOROOT
export GOROOT_FINAL = "${libdir}/${TARGET_SYS}/go"
export GOBIN_FINAL
export GOPKG_FINAL = "${GOROOT_FINAL}/pkg/${GOOS}_${GOARCH}"
export GOSRC_FINAL = "${GOROOT_FINAL}/src"
export GO_GCFLAGS = "${TARGET_CFLAGS}"
export GO_LDFLAGS = "${TARGET_LDFLAGS}"
export CGO_CFLAGS = "${TARGET_CC_ARCH}${TOOLCHAIN_OPTIONS} ${TARGET_CFLAGS}"
export CGO_CPPFLAGS = "${TARGET_CPPFLAGS}"
export CGO_CXXFLAGS = "${TARGET_CC_ARCH}${TOOLCHAIN_OPTIONS} ${TARGET_CXXFLAGS}"
export CGO_LDFLAGS = "${TARGET_CC_ARCH}${TOOLCHAIN_OPTIONS} ${TARGET_LDFLAGS}"

FILES_${PN}-staticdev += "${GOSRC_FINAL}/${GO_IMPORT}"
FILES_${PN}-staticdev += "${GOPKG_FINAL}/${GO_IMPORT}*"

GO_INSTALL ?= "${GO_IMPORT}/..."

go_do_compile() {
	GOPATH=${S}:${STAGING_LIBDIR}/${TARGET_SYS}/go go env
	if [ -n "${GO_INSTALL}" ]; then
		GOPATH=${S}:${STAGING_LIBDIR}/${TARGET_SYS}/go go install ${GOBUILDFLAGS} ${GO_INSTALL}
	fi
}

go_do_install() {
	rm -rf ${WORKDIR}/staging
	install -d ${WORKDIR}/staging${GOROOT_FINAL} ${D}${GOROOT_FINAL}
	tar -C ${S} -cf - . | tar -C ${WORKDIR}/staging${GOROOT_FINAL} -xpvf -

	find ${WORKDIR}/staging${GOROOT_FINAL} \( \
		-name \*.indirectionsymlink -o \
		-name .git\* -o                \
		-name .hg -o                   \
		-name .svn -o                  \
		-name .pc\* -o                 \
		-name patches\*                \
		\) -print0 | \
	xargs -r0 rm -rf

	tar -C ${WORKDIR}/staging${GOROOT_FINAL} -cf - . | \
	tar -C ${D}${GOROOT_FINAL} -xpvf -

	chown -R root:root "${D}${GOROOT_FINAL}"

	if [ -e "${D}${GOBIN_FINAL}" ]; then
		install -d -m 0755 "${D}${bindir}"
		find "${D}${GOBIN_FINAL}" ! -type d -print0 | xargs -r0 mv --target-directory="${D}${bindir}"
		rmdir -p "${D}${GOBIN_FINAL}" || true
	fi
}
do_install[dirs] =+ "${WORKDIR}/staging"
do_install[cleandirs] += "${WORKDIR}/staging"

EXPORT_FUNCTIONS do_compile do_install
