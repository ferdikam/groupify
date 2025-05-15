<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Souscription extends Model
{
    /** @use HasFactory<\Database\Factories\SouscriptionFactory> */
    use HasFactory;

    public function groupage(): BelongsTo
    {
        return $this->belongsTo(Groupage::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
