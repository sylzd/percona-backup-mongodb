GOCACHE?=off
GOLANG_DOCKERHUB_TAG?=1.11-stretch
GO_TEST_PATH?=./...
GO_TEST_EXTRA?=
GO_TEST_COVER_PROFILE?=cover.out
GO_TEST_CODECOV?=
GO_BUILD_LDFLAGS?=-w -s

TEST_PSMDB_VERSION?=latest
TEST_MONGODB_ADMIN_USERNAME?=admin
TEST_MONGODB_ADMIN_PASSWORD?=admin123456
TEST_MONGODB_USERNAME?=test
TEST_MONGODB_PASSWORD?=123456
TEST_MONGODB_S1_RS?=rs1
TEST_MONGODB_S1_PRIMARY_PORT?=17001
TEST_MONGODB_S1_SECONDARY1_PORT?=17002
TEST_MONGODB_S1_SECONDARY2_PORT?=17003
TEST_MONGODB_S2_RS?=rs2
TEST_MONGODB_S2_PRIMARY_PORT?=17004
TEST_MONGODB_S2_SECONDARY1_PORT?=17005
TEST_MONGODB_S2_SECONDARY2_PORT?=17006
TEST_MONGODB_CONFIGSVR_RS?=csReplSet
TEST_MONGODB_CONFIGSVR1_PORT?=17007
TEST_MONGODB_CONFIGSVR2_PORT?=17008
TEST_MONGODB_CONFIGSVR3_PORT?=17009
TEST_MONGODB_MONGOS_PORT?=17000

AWS_ACCESS_KEY_ID?=
AWS_SECRET_ACCESS_KEY?=

all: mongodb-backup-admin mongodb-backup-agent mongodb-backupd

$(GOPATH)/bin/dep:
	go get -ldflags="-w -s" github.com/golang/dep/cmd/dep

vendor: $(GOPATH)/bin/dep Gopkg.lock Gopkg.toml
	$(GOPATH)/bin/dep ensure

define TEST_ENV
	AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	GOCACHE=$(GOCACHE) \
	GOLANG_DOCKERHUB_TAG=$(GOLANG_DOCKERHUB_TAG) \
	TEST_MONGODB_ADMIN_USERNAME=$(TEST_MONGODB_ADMIN_USERNAME) \
	TEST_MONGODB_ADMIN_PASSWORD=$(TEST_MONGODB_ADMIN_PASSWORD) \
	TEST_MONGODB_USERNAME=$(TEST_MONGODB_USERNAME) \
	TEST_MONGODB_PASSWORD=$(TEST_MONGODB_PASSWORD) \
	TEST_MONGODB_S1_RS=$(TEST_MONGODB_S1_RS) \
	TEST_MONGODB_S1_PRIMARY_PORT=$(TEST_MONGODB_S1_PRIMARY_PORT) \
	TEST_MONGODB_S1_SECONDARY1_PORT=$(TEST_MONGODB_S1_SECONDARY1_PORT) \
	TEST_MONGODB_S1_SECONDARY2_PORT=$(TEST_MONGODB_S1_SECONDARY2_PORT) \
	TEST_MONGODB_S2_RS=$(TEST_MONGODB_S2_RS) \
	TEST_MONGODB_S2_PRIMARY_PORT=$(TEST_MONGODB_S2_PRIMARY_PORT) \
	TEST_MONGODB_S2_SECONDARY1_PORT=$(TEST_MONGODB_S2_SECONDARY1_PORT) \
	TEST_MONGODB_S2_SECONDARY2_PORT=$(TEST_MONGODB_S2_SECONDARY2_PORT) \
	TEST_MONGODB_CONFIGSVR_RS=$(TEST_MONGODB_CONFIGSVR_RS) \
	TEST_MONGODB_CONFIGSVR1_PORT=$(TEST_MONGODB_CONFIGSVR1_PORT) \
	TEST_MONGODB_CONFIGSVR2_PORT=$(TEST_MONGODB_CONFIGSVR2_PORT) \
	TEST_MONGODB_CONFIGSVR3_PORT=$(TEST_MONGODB_CONFIGSVR3_PORT) \
	TEST_MONGODB_MONGOS_PORT=$(TEST_MONGODB_MONGOS_PORT) \
	TEST_PSMDB_VERSION=$(TEST_PSMDB_VERSION)
endef

env:
	@echo -e $(TEST_ENV) | tr ' ' '\n' >.env

test-race: env vendor
ifeq ($(GO_TEST_CODECOV), true)
	$(shell cat .env) \
	go test -v -race -coverprofile=$(GO_TEST_COVER_PROFILE) -covermode=atomic $(GO_TEST_EXTRA) $(GO_TEST_PATH)
else
	$(shell cat .env) \
	go test -v -race -covermode=atomic $(GO_TEST_EXTRA) $(GO_TEST_PATH)
endif
	
test: env vendor
	$(shell cat .env) \
	go test -covermode=atomic -count 1 -race -timeout 2m $(GO_TEST_EXTRA) $(GO_TEST_PATH)

test-cluster: env
	docker-compose up \
	--detach \
	--force-recreate \
	--renew-anon-volumes \
	init
	docker/test/init-cluster-wait.sh

test-cluster-clean: env
	docker-compose down -v

test-full: env test-cluster-clean test-cluster
	docker-compose up \
	--build \
	--no-deps \
	--force-recreate \
	--renew-anon-volumes \
	--abort-on-container-exit \
	test

test-clean: test-cluster-clean
	rm -rf test-out 2>/dev/null || true

mongodb-backup-agent: vendor cli/mongodb-backup-agent/main.go grpc/*/*.go internal/*/*.go mdbstructs/*.go proto/*/*.go
	go build -ldflags="$(GO_BUILD_LDFLAGS)" -o mongodb-backup-agent cli/mongodb-backup-agent/main.go

mongodb-backup-admin: vendor cli/mongodb-backup-admin/main.go grpc/*/*.go internal/*/*.go proto/*/*.go
	go build -ldflags="$(GO_BUILD_LDFLAGS)" -o mongodb-backup-admin cli/mongodb-backup-admin/main.go

mongodb-backupd: vendor cli/mongodb-backupd/main.go grpc/*/*.go internal/*/*.go mdbstructs/*.go proto/*/*.go
	go build -ldflags="$(GO_BUILD_LDFLAGS)" -o mongodb-backupd cli/mongodb-backupd/main.go

clean:
	rm -rf mongodb-backup-agent mongodb-backup-admin mongodb-backupd vendor 2>/dev/null || true
