package sharded

import (
	"log"

	"github.com/percona/percona-backup-mongodb/e2e-tests/pkg/pbm"
)

func (c *Cluster) ClockSkew() {
	err := pbm.ClockSkew("rs2", "+90m", "unix:///var/run/docker.sock")
	if err != nil {
		log.Fatalln("ERROR: clock skew for rs2:", err)
	}

	log.Println("[START] Basic Backup & Restore / ClockSkew", "rs2", "+90m")
	c.BackupAndRestore()
	log.Println("[DONE] Basic Backup & Restore / ClockSkew", "rs2", "+90m")

	log.Println("[START] Backup Data Bounds Check / ClockSkew", "rs2", "+90m")
	c.BackupBoundsCheck()
	log.Println("[DONE] Backup Data Bounds Check / ClockSkew", "rs2", "+90m")

	err = pbm.ClockSkew("rs1", "-195m", "unix:///var/run/docker.sock")
	if err != nil {
		log.Fatalln("ERROR: clock skew for rs1:", err)
	}

	log.Println("[START] Basic Backup & Restore / ClockSkew", "rs2", "+90m", "rs1", "-195m")
	c.BackupAndRestore()
	log.Println("[DONE] Basic Backup & Restore / ClockSkew", "rs2", "+90m", "rs1", "-195m")

	log.Println("[START] Backup Data Bounds Check / ClockSkew", "rs2", "+90m", "rs1", "-195m")
	c.BackupBoundsCheck()
	log.Println("[DONE] Backup Data Bounds Check / ClockSkew", "rs2", "+90m", "rs1", "-195m")

	err = pbm.ClockSkew("cfg", "+2d", "unix:///var/run/docker.sock")
	if err != nil {
		log.Fatalln("ERROR: clock skew for cfg:", err)
	}

	log.Println("[START] Basic Backup & Restore / ClockSkew", "rs2", "+90m", "rs1", "-195m", "cfg", "+2d")
	c.BackupAndRestore()
	log.Println("[DONE] Basic Backup & Restore / ClockSkew", "rs2", "+90m", "rs1", "-195m", "cfg", "+2d")

	log.Println("[START] Backup Data Bounds Check / ClockSkew", "rs2", "+90m", "rs1", "-195m", "cfg", "+2d")
	c.BackupBoundsCheck()
	log.Println("[DONE] Backup Data Bounds Check / ClockSkew", "rs2", "+90m", "rs1", "-195m", "cfg", "+2d")
}