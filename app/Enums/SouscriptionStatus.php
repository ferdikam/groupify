<?php

namespace App\Enums;

enum SouscriptionStatus
{
    case PENDING;
    case PARTIALLY_PAID;
    case FULL_PAID;
    case DELIVERED;

    public function label(): string
    {
        return match ($this) {
            SouscriptionStatus::PENDING => __('en attente'),
            SouscriptionStatus::PARTIALLY_PAID => __('payé partiellement'),
            SouscriptionStatus::FULL_PAID => __('payé totalement'),
            SouscriptionStatus::DELIVERED => __('livré'),
        };
    }

    public function color(): string
    {
        return match ($this) {
            SouscriptionStatus::PENDING => 'bg-gray-400',
            SouscriptionStatus::PARTIALLY_PAID => 'bg-green-400',
            SouscriptionStatus::FULL_PAID => 'bg-blue-400',
            SouscriptionStatus::DELIVERED => 'bg-yellow-400',
        };
    }
}
