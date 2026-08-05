/*
  Warnings:

  - You are about to drop the column `tableId` on the `order` table. All the data in the column will be lost.
  - You are about to drop the `table` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `mesaId` to the `Order` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE `order` DROP FOREIGN KEY `Order_tableId_fkey`;

-- DropIndex
DROP INDEX `Order_tableId_fkey` ON `order`;

-- AlterTable
ALTER TABLE `order` DROP COLUMN `tableId`,
    ADD COLUMN `mesaId` INTEGER NOT NULL,
    MODIFY `status` ENUM('PENDIENTE', 'PREPARANDO', 'LISTO', 'ENTREGADO', 'PAGADO', 'CANCELADO') NOT NULL DEFAULT 'PENDIENTE';

-- DropTable
DROP TABLE `table`;

-- CreateTable
CREATE TABLE `Mesa` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `number` INTEGER NOT NULL,
    `status` ENUM('DISPONIBLE', 'OCUPADA', 'RESERVADA') NOT NULL DEFAULT 'DISPONIBLE',

    UNIQUE INDEX `Mesa_number_key`(`number`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `Order` ADD CONSTRAINT `Order_mesaId_fkey` FOREIGN KEY (`mesaId`) REFERENCES `Mesa`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
