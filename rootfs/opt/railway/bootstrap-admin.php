<?php
// Creates the first (super admin) user on an empty database, then turns
// open registration off. Does nothing once any user exists.
declare(strict_types=1);

require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Actions\CreateUser;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

$hasUsers = User::count() > 0;
if (in_array('--check', $argv, true)) {
    exit($hasUsers ? 10 : 0);
}
if ($hasUsers) {
    fwrite(STDOUT, "railway: users exist, admin bootstrap skipped\n");
    exit(0);
}

$email = strtolower(trim((string) getenv('ADMIN_EMAIL')));
$password = (string) getenv('ADMIN_PASSWORD');
$name = trim((string) getenv('ADMIN_NAME')) ?: 'Admin';

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "railway: ADMIN_EMAIL is missing or not a valid email address\n");
    exit(1);
}
if (strlen($password) < 12) {
    fwrite(STDERR, "railway: ADMIN_PASSWORD is missing or shorter than 12 characters\n");
    exit(1);
}

$user = (new CreateUser())->handle([
    'name' => $name,
    'email' => $email,
    'password' => Hash::make($password),
]);
$user->forceFill(['email_verified_at' => now()])->save();

$setting = Setting::firstOrCreate();
$setting->update(['registration' => false]);

if (!$user->isAdmin() || Setting::first()->registration) {
    fwrite(STDERR, "railway: admin role or closed registration could not be confirmed\n");
    exit(1);
}
fwrite(STDOUT, "railway: admin {$email} created, open sign-up switched off\n");
