BUILD_DIR ?= builddir
BINARY := $(BUILD_DIR)/src/astolfosplayer
MESON ?= meson
NINJA ?= ninja

.PHONY: compile run clean proto

compile:
	@echo "Configuring and compiling (build dir: $(BUILD_DIR))"
	$(MESON) setup $(BUILD_DIR) --reconfigure
	$(MESON) compile -C $(BUILD_DIR)

run: compile
	@echo "Running with local schemas and icons from $(BUILD_DIR)/data"
	GSETTINGS_SCHEMA_DIR="$(PWD)/$(BUILD_DIR)/data" \
	XDG_DATA_DIRS="$(PWD)/$(BUILD_DIR)/data:$$XDG_DATA_DIRS" \
	$(BINARY)

clean:
	@if [ -d "$(BUILD_DIR)" ]; then \
		$(NINJA) -C $(BUILD_DIR) -t clean || true; \
	fi
	rm -rf $(BUILD_DIR)

proto:
	@echo "Generating protobuf C files"
	mkdir -p src/proto
	protoc --c_out=src/proto --proto_path=protos/proto protos/proto/auth/auth.proto protos/proto/sync/sync.proto protos/proto/file/file.proto
