<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\Pivot;

class GroupageProduit extends Pivot
{
    public function groupage():BelongsTo
    {
        return $this->belongsTo(Groupage::class);
    }

    public function produit():BelongsTo
    {
        return $this->belongsTo(Produit::class);
    }
}