<?php

use App\Http\Controllers\Groupage\GroupagesController;
use App\Livewire\Settings\Appearance;
use App\Livewire\Settings\Password;
use App\Livewire\Settings\Profile;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
})->name('home');

Route::view('dashboard', 'dashboard')
    ->middleware(['auth', 'verified'])
    ->name('dashboard');

Route::middleware(['auth'])->group(function () {

    Route::get('/groupages', [GroupagesController::class, 'index'])->name('groupages.index');
    Route::get('/groupages/create', [GroupagesController::class, 'create'])->name('groupages.create');
    Route::post('/groupages', [GroupagesController::class, 'store'])->name('groupages.store');
    Route::get('/groupages/{groupage}', [GroupagesController::class, 'show'])->name('groupages.show');

    Route::redirect('settings', 'settings/profile');

    Route::get('settings/profile', Profile::class)->name('settings.profile');
    Route::get('settings/password', Password::class)->name('settings.password');
    Route::get('settings/appearance', Appearance::class)->name('settings.appearance');
});

require __DIR__.'/auth.php';
