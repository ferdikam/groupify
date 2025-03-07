<?php

namespace App\Http\Controllers\Groupage;

use App\Http\Controllers\Controller;
use App\Models\Groupage;
use Illuminate\Http\Request;

class IndexController extends Controller
{
    /**
     * Handle the incoming request.
     */
    public function __invoke(Request $request)
    {
        if (! request()->user()->isAdmin()) {
            abort(403);
        }

        $groupages = Groupage::query()
            ->latest()
            ->get();

        return view('groupage.index', [
            'groupages' => $groupages,
        ]);
    }
}
