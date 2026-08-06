-- DropForeignKey
ALTER TABLE `order` DROP FOREIGN KEY `Order_tableId_fkey`;

-- DropIndex
DROP INDEX `Order_tableId_fkey` ON `order`;

-- AlterTable
ALTER TABLE `order` ADD COLUMN `amountReceived` DOUBLE NULL,
    ADD COLUMN `change` DOUBLE NULL,
    ADD COLUMN `completedAt` DATETIME(3) NULL,
    ADD COLUMN `paymentMethod` VARCHAR(191) NULL,
    ADD COLUMN `serviceType` VARCHAR(191) NOT NULL DEFAULT 'takeaway',
    MODIFY `tableId` INTEGER NULL;

-- AlterTable
ALTER TABLE `orderdetail` ADD COLUMN `note` VARCHAR(191) NULL;

-- AlterTable
ALTER TABLE `product` ADD COLUMN `active` BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE `table` ADD COLUMN `qrCode` VARCHAR(191) NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX `Table_qrCode_key` ON `Table`(`qrCode`);

-- AddForeignKey
ALTER TABLE `Order` ADD CONSTRAINT `Order_tableId_fkey` FOREIGN KEY (`tableId`) REFERENCES `Table`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

